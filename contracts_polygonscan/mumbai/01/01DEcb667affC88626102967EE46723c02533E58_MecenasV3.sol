// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";


interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


interface CreamYield {
    
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function underlying() external view returns (address);
}


contract MecenasV3 is ReentrancyGuard {

    address public constant EMPTY_ADDRESS = address(0);
    uint public immutable LOT_DEPOSIT;
    uint public immutable LOCK_PLAYERS;
    uint public immutable LOCK_LOTTERY;

    CreamYield public marketcream;
    ERC20 public underlying;
    
    uint public totalseekerinterest;
    uint public totaldevelopinterest;
    uint public reservevalue;
    uint public totalinterestpaid;
    uint public totalreservepaid;
    uint public supporters;
    uint public lockdeposits;
    uint public jackpotvalue;
    uint public interestvalue;
    uint private nonce;
    uint private blockNumber;
    
    bool public spinning;
    bool public picking;

    uint public jackpotsettled;
    uint public timejackpot;
    uint public supporterslottery;
    uint public jackpotspaid;
    uint public lastjackpotresult;
    address public lastjackpotwinner;
    uint public lastjackpotamount;
    uint public lastjackpotdate;
    uint public developsettled;
    uint public seekersettled;
    
    uint public lastjackpotcounter;
    
    uint public balancedonations;
    uint public totaldonations;
    uint public totaldonationspaid;
    mapping(address => uint) public balancedonators;
    mapping(address => uint) public balancepatrons;
    uint public balancepool;

    uint public decimalstoken;
    string public nametoken;

    address[] private players;
    
    mapping(address => uint) public timeplayers;
    
    mapping(address => uint) private indexplayers;
    
    address public owner;
    address public developer;
    address public seeker;

    uint public lotterycounter;
    
    struct Lottery {
        uint lotteryid;
        uint lotterydate;
        uint lotteryresult;
        address lotterywinner;
        uint lotteryamount;
    }    
    
    Lottery[] public LotteryResults;
    
    event Deposit(address indexed from, uint amount);
    event Withdraw(address indexed to, uint amount);
    event DepositDonation(address indexed from, uint amount);
    event WithdrawDonation(address indexed to, uint amount);
    event CollectInterest(address indexed to, uint amount);
    event CollectReserve(address indexed to, uint amount);
    event PayWinner(address indexed to, uint amount);
    event PayDeveloper(address indexed to, uint amount);
    event PaySeeker(address indexed to, uint amount);
    event ChangeOwner(address indexed oldowner, address indexed newowner);
    event ChangeDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangeSeeker(address indexed oldseeker, address indexed newseeker);
    event ChangePoolLock(address indexed ownerchanger, uint oldlock, uint newlock);
    event LotteryAwarded(uint counter, uint date, address indexed thewinner, uint amount, uint result);
    
    
    constructor(address _owner, address _marketcream, address _developer, address _seeker, uint _mindeposit, uint _agedeposit, uint _agelottery) {
        
        marketcream = CreamYield(_marketcream);
        underlying = ERC20(marketcream.underlying());
        owner = _owner;
        developer = _developer;
        seeker = _seeker;
        LOT_DEPOSIT = _mindeposit;
        LOCK_PLAYERS = _agedeposit;
        LOCK_LOTTERY = _agelottery;
        decimalstoken = underlying.decimals();
        nametoken = underlying.symbol();
    }


    // this modifier checks if msg.sender is the owner
    
    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    
    // this function modifies the address of the owner
    
    function transferowner(address _newowner) external onlyowner {
        require(_newowner != EMPTY_ADDRESS);
        address oldowner = owner;
        owner = _newowner;
    
        emit ChangeOwner(oldowner, owner);
    }


    // this function modifies the address of the developer

    function transferdeveloper(address _newdeveloper) external {
        require(_newdeveloper != EMPTY_ADDRESS && msg.sender == developer);
        address olddeveloper = developer;
        developer = _newdeveloper;
    
        emit ChangeDeveloper(olddeveloper, developer);
    }


    // this function modifies the address of the seeker

    function transferseeker(address _newseeker) external {
        require(_newseeker != EMPTY_ADDRESS && msg.sender == seeker);
        address oldseeker = seeker;
        seeker = _newseeker;
    
        emit ChangeSeeker(oldseeker, seeker);
    }


    // this function is used to lock or unlock functions deposit() and depositdonation()
    // 0 = unlock 
    // 1 = lock
    
    function lockpool(uint _lockdeposits) external onlyowner {
        require(_lockdeposits == 1 || _lockdeposits == 0);
        uint oldlockdeposits = lockdeposits;
        lockdeposits = _lockdeposits;
    
        emit ChangePoolLock(owner, oldlockdeposits, lockdeposits);
    }
    
    
    // this function is used to deposit underlying and transfer it to yield source
    // evaluates if is a jackpot participant
    
    function deposit(uint _amount) external nonReentrant {
        require(spinning == false && lockdeposits == 0 && msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount);
        require(underlying.allowance(msg.sender, address(this)) >= _amount);
        
        require(underlying.transferFrom(msg.sender, address(this), _amount) == true);
        
        uint balancesupporter = balancepatrons[msg.sender];
        
        if (balancesupporter == 0) {
            supporters += 1;
            if (_amount >= LOT_DEPOSIT) {
                supporterslottery += 1;
                players.push(msg.sender);
                indexplayers[msg.sender] = players.length - 1;
                timeplayers[msg.sender] = block.timestamp;
            } 
        }
        
        if (balancesupporter > 0) {
            if (balancesupporter < LOT_DEPOSIT && (balancesupporter + _amount) >= LOT_DEPOSIT) {
                supporterslottery += 1;
                players.push(msg.sender);
                indexplayers[msg.sender] = players.length - 1;
                timeplayers[msg.sender] = block.timestamp;
            }
        }
        
        if (supporterslottery > 0 && timejackpot == 0 && spinning == false) {
            timejackpot = block.timestamp;
        }
        
        require(underlying.approve(address(marketcream), _amount) == true);
        balancepatrons[msg.sender] += _amount;
        balancepool += _amount;
        
        require(marketcream.mint(_amount) == 0);   
        
        emit Deposit(msg.sender, _amount);
    }
    
    
    // this function is used to deposit underlying and transfer it to yield source
  
    function depositdonation(uint _amount) external nonReentrant {
        require(lockdeposits == 0 && msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount);
        require(underlying.allowance(msg.sender, address(this)) >= _amount);
        
        require(underlying.transferFrom(msg.sender, address(this), _amount) == true);
        
        require(underlying.approve(address(marketcream), _amount) == true);
        
        balancedonations += _amount;
        require(marketcream.mint(_amount) == 0);   
        
        totaldonations += _amount;
        balancedonators[msg.sender] += _amount;
        
        emit DepositDonation(msg.sender, _amount);
    }
    
    
    // this function is used to redeem underlying from yield source and withdraw
    // evaluates if is a jackpot participant
    
    function withdraw(uint _amount) external nonReentrant {
        require(spinning == false && msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && balancepatrons[msg.sender] >= _amount);
        require(marketcream.getCash() >= _amount);
        
        require(marketcream.redeemUnderlying(_amount) == 0);
        
        balancepatrons[msg.sender] -= _amount; 
        balancepool -= _amount;
        
        uint balancesupporter = balancepatrons[msg.sender];
        
        if (balancesupporter == 0) {
            supporters -= 1;
        }
    
        if (balancesupporter >= 0) {
            if (balancesupporter < LOT_DEPOSIT && (balancesupporter + _amount) >= LOT_DEPOSIT) {
                supporterslottery -= 1;
                timeplayers[msg.sender] = 0;
                
                uint index = indexplayers[msg.sender];
                uint indexmove = players.length - 1;
                address addressmove = players[indexmove];
                
                if (index == indexmove || players.length == 1) {
                    delete indexplayers[msg.sender];
                    players.pop();
                
                    
                } else {
                    delete indexplayers[msg.sender];
                    players[index] = addressmove;
                    indexplayers[addressmove] = index;
                    players.pop();
                }
                    
            }
        } 
        
        if (supporterslottery == 0) {
            timejackpot = 0;
            spinning = false;
            picking = false;
            jackpotsettled = 0;
            developsettled = 0;
            seekersettled = 0;
        }    
        
        require(underlying.transfer(msg.sender, _amount) == true);
    
        emit Withdraw(msg.sender, _amount);
    }


    // this function accrues the yield and splits into interests, reserves and jackpot
    
    function splityield() internal {
        uint interest = interestaccrued();
        
        uint totransferinterest = interest * (50 * 10 ** decimalstoken / 100);
        totransferinterest = totransferinterest / 10 ** decimalstoken;
        
        interestvalue += totransferinterest;
        
        uint jackpotinterest = interest * (25 * 10 ** decimalstoken / 100);
        jackpotinterest = jackpotinterest / 10 ** decimalstoken;
        jackpotvalue += jackpotinterest;
        
        uint reserveinterest = interest - totransferinterest - jackpotinterest;
        reservevalue += reserveinterest;
        
        assert(interest == (totransferinterest + jackpotinterest + reserveinterest));
        assert(marketcream.balanceOfUnderlying(address(this)) >= (interestvalue + jackpotvalue + reservevalue + balancepool + balancedonations));
    }


    // this function is used to calculate interest accrued in yield source
    
    function interestaccrued() internal returns (uint) {
        uint interest = (marketcream.balanceOfUnderlying(address(this)) - balancepool - balancedonations - reservevalue - jackpotvalue - interestvalue); 
        return interest;
    }


    // this function is used to settle the prize and seeds with block number and nonce to be used to generate random number
    
    function settlejackpot() external nonReentrant {
        
        require(spinning == false && supporterslottery > 0 && timejackpot > 0 && block.number - blockNumber > 0);
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;
        require(totaltime >= LOCK_LOTTERY);

        spinning = true;
        timejackpot = 0;
        blockNumber = block.number;

        splityield();
    
        require(jackpotvalue > 0);
        
        jackpotsettled = jackpotvalue;
        uint distjackpot = jackpotsettled;
        
        developsettled = distjackpot * (20 * 10 ** decimalstoken / 100);
        developsettled = developsettled / 10 ** decimalstoken;
        seekersettled = distjackpot * (5 * 10 ** decimalstoken / 100);
        seekersettled = seekersettled / 10 ** decimalstoken;
        
        jackpotsettled = jackpotsettled - developsettled - seekersettled;
        
        assert(distjackpot == (jackpotsettled + developsettled + seekersettled));
        
        nonce += 1;
        picking = true;
    }
    
    
    // this function generates a random number using future Blockhash
    
    function generaterandomnumber() internal view returns (uint) {
        uint randnum = uint(keccak256(abi.encode(blockhash(blockNumber), nonce))) % players.length;
        return randnum;  
    }


    // this function is used to pick a winner, redeem underlying from yield source and transfer to
    // the winner, to the developer and to the seeker
    
    function pickawinner() external nonReentrant {
        
        require(spinning == true && picking == true && block.number - blockNumber > 0 && supporterslottery > 0);
        
        picking = false;
        uint toredeem =  jackpotsettled + developsettled + seekersettled;
        require(marketcream.getCash() >= toredeem);  
        
        uint totransferbeneficiary = jackpotsettled;
        uint totransferdevelop = developsettled;
        uint totransferseeker = seekersettled;
        
        jackpotsettled = 0;
        developsettled = 0;
        seekersettled = 0;
        
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
        
            address candidate = players[randomnumber];
        
                if (timeplayers[candidate] > 0 && balancepatrons[candidate] >= LOT_DEPOSIT) { 
        
                    uint totaltime = end - timeplayers[candidate];
                        if (totaltime >= LOCK_PLAYERS) {
                            winner = 1;
                            beneficiary = candidate;
                        }
                }
            
            nonce++; 
        }        

        if (winner == 1) {
            
            jackpotspaid += totransferbeneficiary;
            totaldevelopinterest += totransferdevelop;
            totalseekerinterest += totransferseeker;
            
            require(marketcream.redeemUnderlying(toredeem) == 0);
            jackpotvalue -= toredeem;
            
            require(underlying.transfer(beneficiary, totransferbeneficiary) == true);
            require(underlying.transfer(developer, totransferdevelop) == true);
            require(underlying.transfer(seeker, totransferseeker) == true);
        
            lastjackpotresult = 1;
            lastjackpotwinner = beneficiary;
            lastjackpotamount = totransferbeneficiary;
            lastjackpotdate = end;
            lastjackpotcounter = lotterycounter;
        
            LotteryResults.push(Lottery(lotterycounter, end, 1, beneficiary, totransferbeneficiary));
        
            emit PayWinner(beneficiary, totransferbeneficiary);
            emit PayDeveloper(developer, totransferdevelop);
            emit PaySeeker(seeker, totransferseeker);
            
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
        
    
    // this function returns the timeleft to execute function settlejackpot()
    // 0 = no time left

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

        if (spinning == false && supporterslottery > 0 && timejackpot > 0 && (block.number - blockNumber) > 0 && totaltime >= LOCK_LOTTERY) {
            return 1;
    
        } else {
            return 2;
        }    
    }        
            
    
    // this function returns if conditions are met to execute function pickawinner()
    // 1 = met
    // 2 = not met 
        
    function calculatepickawinner() public view returns (uint) {
        
        uint toredeem = jackpotsettled + developsettled + seekersettled;
        uint metwinner;
        
            
            if (spinning == true && block.number - blockNumber > 0 && supporterslottery > 0 && marketcream.getCash() >= toredeem) {
                metwinner = 1;
        
            } else {
                metwinner = 2;
            }
        
        
        return metwinner;
    }
    
    
    // this function returns if account is the owner
    // 1 = is owner
    // 2 = is not owner
    
    function verifyowner(address _account) public view returns (uint) {
        
        if (_account == owner) {
            return 1;
        } else {
            return 2;
        }
    }
    
  
    // this  function returns an array of struct of jackpots drawn results
  
    function getLotteryResults() external view returns (Lottery[] memory) {
    return LotteryResults;
    }
  
    
    // this function is used to redeem underlying from yield source and withdraw interests and reserves
    // flag 1 = interests
    // flag 2 = reserves

    function withdrawyield(uint _amount, uint _flag) external nonReentrant onlyowner {
        require(_amount > 0 && (_flag == 1 || _flag == 2));
        
        splityield();
        
        if (_flag == 1) {
        require(_amount <= interestvalue);
        }
        
        if (_flag == 2) {
        require(_amount <= reservevalue);
        }
        
        require(marketcream.getCash() >= _amount);  
        
        uint totransferinterestnet = _amount;
        
        if (_flag == 1) {
        totalinterestpaid += _amount;
        }
        
        if (_flag == 2) {
        totalreservepaid += _amount;
        }
        
        require(marketcream.redeemUnderlying(totransferinterestnet) == 0);
        
        if (_flag == 1) {
        interestvalue -= _amount;
        }
        
        if (_flag == 2) {
        reservevalue -= _amount;
        }
        
        require(underlying.transfer(owner, totransferinterestnet) == true);

        if (_flag == 1) {
        emit CollectInterest(owner, totransferinterestnet);
        }
        
        if (_flag == 2) {
        emit CollectReserve(owner, totransferinterestnet);
        }
    }

    
    
    // this function is used to redeem underlying from yield source and withdraw donations     
    
    function withdrawdonations(uint _amount) external nonReentrant onlyowner {
        require(_amount > 0);
        require(balancedonations >= _amount);
        require(marketcream.getCash() >= _amount);  
        
        require(marketcream.redeemUnderlying(_amount) == 0);
        balancedonations -= _amount;
        totaldonationspaid += _amount;
        
        require(underlying.transfer(owner, _amount) == true);

        emit WithdrawDonation(owner, _amount);
    }
    

    // this function returns yield generated
    // _amount = balance of underlying of yieldsource
    
    function calculateinterest(uint _amount) external view returns(uint, uint, uint) {
        
        uint yield = (_amount - balancepool - balancedonations - reservevalue - jackpotvalue - interestvalue);
        
        uint interest = yield * (50 * 10 ** decimalstoken / 100);
        interest = interest / 10 ** decimalstoken;
        
        uint reserve = yield * (25 * 10 ** decimalstoken / 100);
        reserve = reserve / 10 ** decimalstoken;
        
        uint jackpot = yield - interest - reserve;
        
        interest = interest + interestvalue;
        reserve = reserve + reservevalue;
        jackpot = jackpot + jackpotvalue - jackpotsettled - developsettled - seekersettled;
    
        jackpot = jackpot * (75 * 10 ** decimalstoken / 100);
        jackpot = jackpot / 10 ** decimalstoken;
        
        return (interest, reserve, jackpot);
    }
    

    // this function returns data to the front end

    function calculatedata() external view returns (uint [] memory) {
        
        uint[] memory datafront = new uint[](23);
        
        datafront[0] = balancepool + balancedonations; // deposits
        datafront[1] = marketcream.getCash(); // liquidity
        datafront[2] = calculatetimeleft(); // leftime lottery
        datafront[3] = calculatesettlejackpot(); // evaluates if conditions are met to settle the lottery
        datafront[4] = calculatepickawinner(); // evaluates if conditions are met to pick a lottery winner
        
        datafront[5] = totalinterestpaid;
        datafront[6] = totalreservepaid;
        datafront[7] = totaldonationspaid;
        datafront[8] = balancedonations;
        
        datafront[9] = totaldonations;
        datafront[10] = jackpotsettled;
        datafront[11] = jackpotspaid;
        
        datafront[12] = lastjackpotamount;
        datafront[13] = supporters;
        datafront[14] = supporterslottery;
        
        datafront[15] = lastjackpotresult;
        datafront[16] = lastjackpotdate;
        datafront[17] = lastjackpotcounter;
        
        datafront[18] = LOT_DEPOSIT;
        datafront[19] = LOCK_PLAYERS;
        datafront[20] = LOCK_LOTTERY;
        
        datafront[21] = decimalstoken;
        datafront[22] = balancepool;
        
        return (datafront);
    }

   
   // this function returns data to the front end
    
    function calculatedataaccount(address _account) external view returns (uint [] memory) {
        require(_account != EMPTY_ADDRESS);

        uint[] memory datafrontaccount = new uint[](6);
        
        datafrontaccount[0] = balancepatrons[_account]; // balance depositors
        datafrontaccount[1] = underlying.balanceOf(_account); // balance wallet underlying depositors
        datafrontaccount[2] = underlying.allowance(_account, address(this)); // allowance underlying depositors behalf pool
        datafrontaccount[3] = lockdeposits;
        datafrontaccount[4] = balancedonators[_account]; // balance donators
        datafrontaccount[5] = verifyowner(_account); // evaluates if caller is the owner of the pool

        return (datafrontaccount);
    }


    // this  function is used by the front end to check conditions of operations
    // flag 1 = deposits
    // flag 2 = donations
    // flag 3 = withdraw
    // flag 4 = withdraw donations
    // flag 5 = withdraw yield

    function checkoperations(uint _amount, uint _amount1, address _account, uint _flag) external view returns (uint) {
        require(_account != EMPTY_ADDRESS && _amount > 0 && _flag > 0);
        
        uint result = 0;
        
        if (lockdeposits == 1 && (_flag == 1 || _flag == 2)) {
            result = 1;
        } else {
            if (spinning == true && (_flag == 1 || _flag == 3)) {
                result = 2;
            } else {
                if (_amount > underlying.balanceOf(_account) && (_flag == 1 || _flag == 2)) {
                    result = 3;
                } else {
                    if (_amount > underlying.allowance(_account, address(this)) && (_flag == 1 || _flag == 2)) {
                        result = 4;
                    } else {
                        if (_amount > balancepatrons[_account] && _flag == 3) {
                            result = 5;            
                        } else {
                             if (verifyowner(_account) == 2 && (_flag == 4 || _flag == 5)) {
                                result = 6;
                            } else {
                                if (_amount > balancedonations && _flag == 4) {
                                    result = 7;
                                } else {
                                    if (_amount > _amount1 && _flag == 5) {
                                        result = 8;
                                    } else {
                                        if (_amount > marketcream.getCash() && (_flag == 3 || _flag == 4 || _flag == 5)) {
                                            result = 9;
                                        }
                                    }
                                }
                            }     
                        }
                    }                        
                }
            }
        }
        
        return result;
    }

}