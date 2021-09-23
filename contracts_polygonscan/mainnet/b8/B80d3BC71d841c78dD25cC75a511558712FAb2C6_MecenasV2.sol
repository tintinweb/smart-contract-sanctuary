// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20m.sol";
import "./ReentrancyGuard.sol";


contract ERC20 {

    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
}


contract CreamYield {
    
    function mint(uint mintAmount) external returns (uint){}
    function redeemUnderlying(uint redeemAmount) external returns (uint) {}
    function balanceOfUnderlying(address owner) external returns (uint) {}
    function getCash() external view returns (uint) {}
}


contract MecenasV2 is ERC20m, ReentrancyGuard {

    address public constant EMPTY_ADDRESS = address(0);
    uint public constant LOT_DEPOSIT = 1;
    uint public constant LOCK_PLAYERS = 60;
    uint public constant LOCK_LOTTERY = 120;

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
    
    
    constructor(address _owner, address _marketcream, address _underlying, address _developer, address _seeker) ERC20m("crMECENASPOOLS", "crMEC") {
        
        marketcream = CreamYield(_marketcream);
        underlying = ERC20(_underlying);
        lockdeposits = 0;
        owner = _owner;
        developer = _developer;
        seeker = _seeker;
        spinning = false;
        picking = false;
    }


    // this modifier checks if msg.sender is the owner
    
    modifier onlyowner() {
        require(msg.sender == owner, "Caller is not the owner");
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


    // this function modifies the address of the developer

    function transferdeveloper(address _newdeveloper) public {
        require(msg.sender != EMPTY_ADDRESS);
        require(_newdeveloper != EMPTY_ADDRESS, "New developer is the zero address");
        require(msg.sender == developer, "Caller is not the developer");
        address olddeveloper = developer;
        developer = _newdeveloper;
    
        emit ChangeDeveloper(olddeveloper, developer);
    }


    // this function modifies the address of the seeker

    function transferseeker(address _newseeker) public {
        require(msg.sender != EMPTY_ADDRESS);
        require(_newseeker != EMPTY_ADDRESS, "New developer is the zero address");
        require(msg.sender == seeker, "Caller is not the seeker");
        address oldseeker = seeker;
        seeker = _newseeker;
    
        emit ChangeSeeker(oldseeker, seeker);
    }


    // this function is used to lock or unlock functions deposit() and depositdonation()
    // 1 = lock
    // 0 = unlock 

    function lockpool(uint _lockdeposits) public onlyowner {
        require(_lockdeposits == 1 || _lockdeposits == 0, "Invalid lock parameter");
        uint oldlockdeposits = lockdeposits;
        lockdeposits = _lockdeposits;
    
        emit ChangePoolLock(owner, oldlockdeposits, lockdeposits);
    }
    
    
    // this function is used to deposit underlying and transfer it to yield source
    // evaluates if is a jackpot participant
    
    function deposit(uint _amount) external nonReentrant {
        require(spinning == false, "Lottery is being drawn");
        require(lockdeposits == 0, "Deposits are suspended");
        require(msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount, "Amount cannot be 0");
        require(underlying.allowance(msg.sender, address(this)) >= _amount, "Allowance is less than spending");
        
        require(underlying.transferFrom(msg.sender, address(this), _amount) == true, "Something went wrong");
        
        uint balancesupporter = balanceOf(msg.sender);
        
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
        _mint(msg.sender, _amount);
        require(marketcream.mint(_amount) == 0);   
        
        emit Deposit(msg.sender, _amount);
    }
    
    
    // this function is used to deposit underlying and transfer it to yield source
  
    function depositdonation(uint _amount) external nonReentrant {
        require(lockdeposits == 0, "Deposits are suspended");
        require(msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && underlying.balanceOf(msg.sender) >= _amount, "Amount cannot be 0");
        require(underlying.allowance(msg.sender, address(this)) >= _amount, "Allowance is less than spending");
        
        require(underlying.transferFrom(msg.sender, address(this), _amount) == true, "Something went wrong");
        
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
        require(spinning == false, "Lottery is being drawn");
        require(msg.sender != EMPTY_ADDRESS);
        require(_amount > 0 && balanceOf(msg.sender) >= _amount, "Amount cannot be 0");
        require(marketcream.getCash() >= _amount, "Not enough market liquidity");
        
        require(marketcream.redeemUnderlying(_amount) == 0, "something went wrong");
        
        _burn(msg.sender, _amount);
        
        uint balancesupporter = balanceOf(msg.sender);
        
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
        
        require(underlying.transfer(msg.sender, _amount) == true, "Something went wrong");
    
        emit Withdraw(msg.sender, _amount);
    }


    // this function accrues the yield
    
    function splityield() internal {
        uint interest = interestaccrued();
        
        uint totransferinterest = interest * (0.5 * 10 ** 18);
        totransferinterest = totransferinterest / 10 ** 18;
        
        interestvalue += totransferinterest;
        
        uint jackpotinterest = interest * (0.25 * 10 ** 18);
        jackpotinterest = jackpotinterest / 10 ** 18;
        jackpotvalue += jackpotinterest;
        
        uint reserveinterest = interest - totransferinterest - jackpotinterest;
        reservevalue += reserveinterest;
        
        assert(interest == (totransferinterest + jackpotinterest + reserveinterest));
        assert(marketcream.balanceOfUnderlying(address(this)) >= (interestvalue + jackpotvalue + reservevalue + totalSupply() + balancedonations));
    }


    // this function is used to redeem underlying from yield source and withdraw interests     

    function withdrawinterest(uint _amount) external nonReentrant onlyowner {
        
        splityield();
        
        require(_amount <= interestvalue, "Not enough interests accrued");
        require(marketcream.getCash() >= _amount, "Not enough market liquidity");  
        
        uint totransferinterestnet = _amount;
        totalinterestpaid += _amount;
        
        require(marketcream.redeemUnderlying(totransferinterestnet) == 0, "Something went wrong");
        interestvalue -= _amount;
        
        require(underlying.transfer(owner, totransferinterestnet) == true, "Something went wrong");

        emit CollectInterest(owner, totransferinterestnet);
    }


    // this function is used to calculate interest accrued in yield source
    
    function interestaccrued() internal returns (uint) {
        uint interest = (marketcream.balanceOfUnderlying(address(this)) - totalSupply() - balancedonations - reservevalue - jackpotvalue - interestvalue); 
        return interest;
    }


    // this function is used to settle the prize and seeds with block number and nonce to be used to generate random number
    
    function settlejackpot() external nonReentrant {
        
        require(spinning == false);
        require(supporterslottery > 0);
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
        uint distjackpot = jackpotsettled;
        
        developsettled = distjackpot * (0.20 * 10 ** 18);
        developsettled = developsettled / 10 ** 18;
        seekersettled = distjackpot * (0.05 * 10 ** 18);
        seekersettled = seekersettled / 10 ** 18;
        
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
        
        require(spinning == true);
        require(picking == true);
        picking = false;
        require(block.number - blockNumber > 0);
        uint toredeem =  jackpotsettled + developsettled + seekersettled;
        require(marketcream.getCash() >= toredeem, "Not enough market liquidity");  
        require(supporterslottery > 0);
        
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
        
                if (timeplayers[candidate] > 0 && balanceOf(candidate) >= LOT_DEPOSIT) { 
        
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
            
            require(marketcream.redeemUnderlying(toredeem) == 0, "Something went wrong");
            jackpotvalue -= toredeem;
            
            require(underlying.transfer(beneficiary, totransferbeneficiary) == true, "Something went wrong");
            require(underlying.transfer(developer, totransferdevelop) == true, "Something went wrong");
            require(underlying.transfer(seeker, totransferseeker) == true, "Something went wrong");
        
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
        
    
    // this function returns the timeleft to execute function settlejackpot() - 0 no time left

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
    
    
    // this function returns if conditions are met to execute function settlejackpot() - 1 met - 2 not met 
    
    function calculatesettlejackpot() public view returns (uint) {
        
        uint end = block.timestamp;
        uint totaltime = end - timejackpot;

        if (spinning == false && supporterslottery > 0 && timejackpot > 0 && (block.number - blockNumber) > 0 && totaltime >= LOCK_LOTTERY) {
            return 1;
    
        } else {
            return 2;
        }    
    }        
            
    
    // this function returns if conditions are met to execute function pickawinner() - 1 met - 2 not met 
        
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
    
    
    // this function returns if account is the owner - 1 is owner - 2 is not owner
    
    function verifyowner(address _account) public view returns (uint) {
        
        if (_account == owner) {
            return 1;
        } else {
            return 2;
        }
    }
    
  
    // this  function returns an array of struct of jackpots drawn results
  
    function getLotteryResults() public view returns (Lottery[] memory) {
    return LotteryResults;
    }
  
    
    // this function is used to redeem underlying from yield source and withdraw reserves     
    
    function withdrawreserves(uint _amount) external nonReentrant onlyowner {
        
        splityield();
        
        require(_amount <= reservevalue, "Not enough reserves accrued");
        
        require(marketcream.getCash() >= _amount, "Not enough market liquidity");  
        
        uint totransferinterestnet = _amount;
        totalreservepaid += _amount;
        
        require(marketcream.redeemUnderlying(totransferinterestnet) == 0, "Something went wrong");
        reservevalue -= _amount;
        
        require(underlying.transfer(owner, totransferinterestnet) == true, "Something went wrong");
    
        emit CollectReserve(owner, totransferinterestnet);
    }
    
    
    // this function is used to redeem underlying from yield source and withdraw donations     
    
    function withdrawdonations(uint _amount) external nonReentrant onlyowner {
        require(_amount > 0 , "Amount cannot be zero");
        require(balancedonations >= _amount, "Not enough donations balance");
        require(marketcream.getCash() >= _amount, "Not enough market liquidity");  
        
        require(marketcream.redeemUnderlying(_amount) == 0, "Something went wrong");
        balancedonations -= _amount;
        totaldonationspaid += _amount;
        
        require(underlying.transfer(owner, _amount) == true, "Something went wrong");

        emit WithdrawDonation(owner, _amount);
    }
    

    // this function returns yield generated. Parameter should be balance of underlying of yieldsource
    
    function calculateinterest(uint _amount) external view returns(uint, uint, uint) {
        
        uint yield = (_amount - totalSupply() - balancedonations - reservevalue - jackpotvalue - interestvalue);
        
        uint interest = yield * (0.5 * 10 ** 18);
        interest = interest / 10 ** 18;
        
        uint reserve = yield * (0.25 * 10 ** 18);
        reserve = reserve / 10 ** 18;
        
        uint jackpot = yield - interest - reserve;
        
        interest = interest + interestvalue;
        reserve = reserve + reservevalue;
        jackpot = jackpot + jackpotvalue - jackpotsettled - developsettled - seekersettled;
    
        jackpot = jackpot * (0.75 * 10 ** 18);
        jackpot = jackpot / 10 ** 18;
        
        return (interest, reserve, jackpot);
    }
    

    // this function returns data to the front end

    function calculatedata() external view returns (uint [] memory) {
        
        uint deposits = totalSupply() + balancedonations;
        uint liquidity = marketcream.getCash();
        uint lefttime = calculatetimeleft();
        uint metsettlejackpot = calculatesettlejackpot();
        uint metpickawinner =  calculatepickawinner();
        
        uint[] memory datafront = new uint[](18);
        
        datafront[0] = deposits;
        datafront[1] = liquidity;
        datafront[2] = lefttime;
        datafront[3] = metsettlejackpot;
        datafront[4] = metpickawinner;
        
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
        
        return (datafront);
    }

   
   // this function returns data to the front end
    
    function calculatedataaccount(address _account) external view returns (uint [] memory) {
        require(_account != EMPTY_ADDRESS);
        uint staked = balanceOf(_account);
        uint balwallet = underlying.balanceOf(_account);
        uint allow = underlying.allowance(_account, address(this));
        uint baldonators = balancedonators[_account];
        uint isowner = verifyowner(_account);
        
        uint spinningstate;
        if (spinning == false) {
            spinningstate = 2;
        } 
        if (spinning == true) {
            spinningstate = 1;
        }
    
        uint[] memory datafrontaccount = new uint[](7);
        
        datafrontaccount[0] = staked;
        datafrontaccount[1] = balwallet;
        datafrontaccount[2] = allow;
        datafrontaccount[3] = lockdeposits;
        datafrontaccount[4] = baldonators;
        datafrontaccount[5] = isowner;
        datafrontaccount[6] = spinningstate;
        
        return (datafrontaccount);
    }


    // this  function is used by the front end. Checks if deposits amount is greater than balance of underlying

    function checkamountdeposits(uint _amount, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_amount > 0);
        if (_amount > underlying.balanceOf(_account)) {
            return 1;
        } else {
            return 0;
        }
    }
        

    // this  function is used by the front end. Checks if underlying withdraw amount is greater than staked

    function checkamountwithdraw(uint _amount, address _account) external view returns (uint) {
        require(_account != EMPTY_ADDRESS);
        require(_amount > 0);
        if (_amount > balanceOf(_account)) {
            return 1;
        } else {
            return 0;
        }
    }


    // this  function is used by the front end. Checks if underlying liquidity is greater than withdraws

    function checkliquidity(uint _amount) external view returns (uint) {
        require(_amount > 0);
        if (marketcream.getCash() >= _amount) {
            return 1;
        } else {
            return 0;
        }
    }


    // this  function is used by the front end. Checks if underlying withdraw of interests, reserves and donations is greater than accrued

    function checkinterestwithdraw(uint _amount1, uint _amount2) external pure returns (uint) {
        require(_amount1 > 0);
    
        if (_amount1 > _amount2) {
            return 1;
        } else {
            return 0;
        }
    }
}