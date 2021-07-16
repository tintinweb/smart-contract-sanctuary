//SourceUnit: trw2V.sol

/*
Following leaders!

These parameters may vary with each new game.
The game ends when the balance reaches 0 TRX and in 24 hours the next game will be starts!
All games under the same contract!

    Plans for Game #1
    1 - Receive infinite 3.7% ROI daily
    2 - Receive 4.7% ROI daily, in 45 days get 211.5%
    3 - Receive 5.7% ROI daily, in 25 days get 142.5%
    4 - Receive 6.7% ROI daily, in 18 dias get 120.6%
    
    100% Safe, 100% Verified Contract, no Risks!
    *y*B**D*S*S*D**B*y*

*/

pragma solidity ^0.5.10;
contract TronBankWinInfiniteV2 {
    uint16 actualGameRun;
    uint64 gameStarted;
    address addressContract;
    address owner;
    uint256 grantTotalInvested;
    address payable ownerWallet;
    uint256 totalInvested;
    uint32 totalInvestors;
    uint32 totalInvestings;
    uint32 constant trxyz = 1000000;
    
    uint64 maxInvestPlan2;
    uint64 maxInvestPlan3;
    uint64 maxInvestPlan4;
    
    uint256 porcentPlan1;
    uint256 porcentPlan2;
    uint256 porcentPlan3;
    uint256 porcentPlan4;
    
    uint16 daysForPlan2;
    uint16 daysForPlan3;
    uint16 daysForPlan4;
    
    uint128 porcentPlan2for100;
    uint128 porcentPlan3for100;
    uint128 porcentPlan4for100;
    
    struct Invest {
        uint8 exist;
        uint64 totalRoiPlan1Invest;
        uint128 roiPlan1DivsPerSecond;
        
        uint64 totalRoiPlan2Invest;
        uint64 actualRoiPlan2Inv;
        uint128 roiPlan2DivsPerSecond;
        uint128 endRoiPlan2PayDateTime;
        
        uint64 totalRoiPlan3Invest;
        uint64 actualRoiPlan3Inv;
        uint128 roiPlan3DivsPerSecond;
        uint128 endRoiPlan3PayDateTime;
        
        uint64 totalRoiPlan4Invest;
        uint64 actualRoiPlan4Inv;
        uint128 roiPlan4DivsPerSecond;
        uint128 endRoiPlan4PayDateTime;
        
        uint64 lastRoiWidrawDateTime;
        uint128 totalWithdraw;
    }
    mapping(address => Invest)[16384] invests;

    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
        addressContract = address(this);
        maxInvestPlan2 = 21000000;
        maxInvestPlan3 = 21000000;
        maxInvestPlan4 = 21000000;
        daysForPlan2 = 45;
        daysForPlan3 = 25;
        daysForPlan4 = 18;
        porcentPlan1 =  37000000000;
        porcentPlan2 =  47000000000;
        porcentPlan3 =  57000000000;
        porcentPlan4 =  67000000000;
        porcentPlan2for100 = 472813;
        porcentPlan3for100 = 701754;
        porcentPlan4for100 = 829187;
        actualGameRun = 1;
        gameStarted = uint64(now);
    }
    modifier onlyOwner {
        require(msg.sender==owner);
        _;
    }
    function withdraw() external {
        Invest storage investor = invests[actualGameRun][msg.sender];
        _payer(investor);
    }
    function invest(uint8 _plan) payable external {
        require(gameStarted<=now,"Game no yet Start!");
        require(msg.value>0,"No invest!");
        require(_plan>0 && _plan<5,"No plan!");
        Invest storage investor = invests[actualGameRun][msg.sender];
        uint256 OwnerF = msg.value / 10;
        ownerWallet.transfer(OwnerF);
        if(_plan>1) {
            if(_plan==2) {
                if((investor.actualRoiPlan2Inv+msg.value) > maxInvestPlan2) {
                    msg.sender.transfer(msg.value-OwnerF);
                    return;
                }
            }
            if(_plan==3) {
                if((investor.actualRoiPlan3Inv+msg.value) > maxInvestPlan3) {
                    msg.sender.transfer(msg.value-OwnerF);
                   return;
                }
            }
            if(_plan==4) {
                if((investor.actualRoiPlan4Inv+msg.value) > maxInvestPlan4) {
                    msg.sender.transfer(msg.value-OwnerF);
                   return;
                }
            }
        }
        totalInvested += msg.value;
        grantTotalInvested += msg.value;
        totalInvestings++;
        if(investor.exist == 0) {
            totalInvestors++;
            investor.exist = 1;
        }
        _payer(investor);
        if(_plan == 1) {
            investor.roiPlan1DivsPerSecond += uint128((msg.value * porcentPlan1) / 86400);
            investor.totalRoiPlan1Invest += uint64(msg.value);
        }
        uint128 toGet;
        if(_plan == 2) {
            if(investor.roiPlan2DivsPerSecond==0) {
                investor.roiPlan2DivsPerSecond = uint128((msg.value * porcentPlan2) / 86400);
            } else {
                if(investor.endRoiPlan2PayDateTime>now) {
                    toGet = (investor.roiPlan2DivsPerSecond * uint128(investor.endRoiPlan2PayDateTime-now) * porcentPlan2for100) / 1000000000000000000;
                    investor.roiPlan2DivsPerSecond = uint128((((msg.value + toGet) * porcentPlan2) ) / 86400);
                } else {
                    investor.roiPlan2DivsPerSecond = uint128((msg.value * porcentPlan2) / 86400);
                }
            }
            investor.totalRoiPlan2Invest += uint64(msg.value);
            investor.actualRoiPlan2Inv = uint64(msg.value + toGet);
            investor.endRoiPlan2PayDateTime = uint64(now+(86400 * daysForPlan2));
        }
        if(_plan == 3) {
            if(investor.roiPlan3DivsPerSecond==0) {
                investor.roiPlan3DivsPerSecond = uint128((msg.value * porcentPlan3) / 86400);
            } else {
                if(investor.endRoiPlan3PayDateTime>now) {
                    toGet = (investor.roiPlan3DivsPerSecond * uint128(investor.endRoiPlan3PayDateTime-now) * porcentPlan3for100) / 1000000000000000000;
                    investor.roiPlan3DivsPerSecond = uint128((((msg.value + toGet) * porcentPlan3)) / 86400);
                } else {
                    investor.roiPlan3DivsPerSecond = uint128((msg.value * porcentPlan3) / 86400);
                }
            }
            investor.totalRoiPlan3Invest += uint64(msg.value);
            investor.actualRoiPlan3Inv = uint64(msg.value + toGet);
            investor.endRoiPlan3PayDateTime = uint64(now+(86400 * daysForPlan3));
        }
        if(_plan == 4) {
            if(investor.roiPlan4DivsPerSecond==0) {
                investor.roiPlan4DivsPerSecond = uint128((msg.value * porcentPlan4) / 86400);
            } else {
                if(investor.endRoiPlan4PayDateTime>now) {
                    toGet = (investor.roiPlan4DivsPerSecond * uint128(investor.endRoiPlan4PayDateTime-now) * porcentPlan4for100) / 1000000000000000000;
                    investor.roiPlan4DivsPerSecond = uint128((((msg.value + toGet) * porcentPlan4)) / 86400);
                } else {
                    investor.roiPlan4DivsPerSecond = uint128((msg.value * porcentPlan4) / 86400);
                }
            }
            investor.totalRoiPlan4Invest += uint64(msg.value);
            investor.actualRoiPlan4Inv = uint64(msg.value + toGet);
            investor.endRoiPlan4PayDateTime = uint64(now+(86400 * daysForPlan4));
        }
    }
    function _payer(Invest storage investor) internal {
        require(investor.exist != 0,"investor no exist!");
        uint128 toWithdraw;
        if(investor.roiPlan1DivsPerSecond>0) toWithdraw = (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan1DivsPerSecond) / trxyz;
        if(investor.roiPlan2DivsPerSecond>0) {
            if(investor.endRoiPlan2PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan2DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoiPlan2PayDateTime > investor.lastRoiWidrawDateTime) {
                    toWithdraw += (uint128(investor.endRoiPlan2PayDateTime - investor.lastRoiWidrawDateTime) * investor.roiPlan2DivsPerSecond) / trxyz;
                }
                investor.roiPlan2DivsPerSecond=0;
            }
        }
        if(investor.roiPlan3DivsPerSecond>0) {
            if(investor.endRoiPlan3PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan3DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoiPlan3PayDateTime > investor.lastRoiWidrawDateTime) { //remain
                    toWithdraw += (uint128(investor.endRoiPlan3PayDateTime - investor.lastRoiWidrawDateTime) * investor.roiPlan3DivsPerSecond) / trxyz;
                }
                investor.roiPlan3DivsPerSecond=0;
            }
        }
        if(investor.roiPlan4DivsPerSecond>0) {
            if(investor.endRoiPlan4PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan4DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoiPlan4PayDateTime > investor.lastRoiWidrawDateTime) { //remain
                    toWithdraw += (uint128(investor.endRoiPlan4PayDateTime - investor.lastRoiWidrawDateTime) * investor.roiPlan4DivsPerSecond) / trxyz;
                }
                investor.roiPlan4DivsPerSecond=0;
            }
        }
        if(toWithdraw>0) {
            toWithdraw /= trxyz;
            if(addressContract.balance>0) {
                if(addressContract.balance>=toWithdraw) {
                    investor.totalWithdraw += toWithdraw;
                    msg.sender.transfer(toWithdraw);
                } else { //GAME END!
                    if(addressContract.balance!=0) {
                        investor.totalWithdraw += uint64(addressContract.balance);
                        msg.sender.transfer(addressContract.balance);
                    }
                    //NEW GAME!
                    actualGameRun++;
                    gameStarted = uint64(now)+86400; //start in 24 hours!
                    totalInvested = 0;
                    totalInvestors = 0;
                    totalInvestings = 0;
                }
            }
        }
        investor.lastRoiWidrawDateTime = uint64(now);
    }
    function toWithdraw() view external returns(uint256 _toWithdraw) {
        Invest memory investor = invests[actualGameRun][msg.sender];
        require(investor.exist != 0,"investor no exist!");
        if(investor.roiPlan1DivsPerSecond>0) _toWithdraw = (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan1DivsPerSecond) / trxyz;
        if(investor.roiPlan2DivsPerSecond>0) {
            if(investor.endRoiPlan2PayDateTime>now) {
                _toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan2DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoiPlan2PayDateTime > investor.lastRoiWidrawDateTime) {
                    _toWithdraw += (uint128(investor.endRoiPlan2PayDateTime - investor.lastRoiWidrawDateTime) * investor.roiPlan2DivsPerSecond) / trxyz;
                }
            }
        }
        if(investor.roiPlan3DivsPerSecond>0) {
            if(investor.endRoiPlan3PayDateTime>now) {
                _toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan3DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoiPlan3PayDateTime > investor.lastRoiWidrawDateTime) {
                    _toWithdraw += (uint128(investor.endRoiPlan3PayDateTime - investor.lastRoiWidrawDateTime) * investor.roiPlan3DivsPerSecond) / trxyz;
                }
            }
        }
        if(investor.roiPlan4DivsPerSecond>0) {
            if(investor.endRoiPlan4PayDateTime>now) {
                _toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiPlan4DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoiPlan4PayDateTime > investor.lastRoiWidrawDateTime) {
                    _toWithdraw += (uint128(investor.endRoiPlan4PayDateTime - investor.lastRoiWidrawDateTime) * investor.roiPlan4DivsPerSecond) / trxyz;
                }
            }
        }
        return(_toWithdraw /= trxyz);
    }
    function toPay(uint8 _plan) view external returns(uint256 _toPay) {
        Invest memory investor = invests[actualGameRun][msg.sender];
        require(investor.exist != 0,"investor no exist!");
        if(_plan==1) return investor.totalRoiPlan1Invest;
        if(_plan==2) return (investor.roiPlan2DivsPerSecond * (investor.endRoiPlan2PayDateTime-uint128(now)) * porcentPlan2for100) / 1000000000000000000;
        if(_plan==3) return (investor.roiPlan3DivsPerSecond * (investor.endRoiPlan3PayDateTime-uint128(now)) * porcentPlan3for100) / 1000000000000000000;
        if(_plan==4) return (investor.roiPlan4DivsPerSecond * (investor.endRoiPlan4PayDateTime-uint128(now)) * porcentPlan4for100) / 1000000000000000000;
    }
    function getInvestorPlansP1() view external returns(
                    uint8 exist, 
                    uint64 totalRoiPlan1Invest,
                    uint128 roiPlan1DivsPerSecond,
                    uint64 totalRoiPlan2Invest,
                    uint64 actualRoiPlan2Inv,
                    uint128 roiPlan2DivsPerSecond,
                    uint128 endRoiPlan2PayDateTime,
                    uint64 totalRoiPlan3Invest,
                    uint64 actualRoiPlan3Inv
                    ) {
        Invest memory investor = invests[actualGameRun][msg.sender];
        return(
            investor.exist,
            investor.totalRoiPlan1Invest,
            investor.roiPlan1DivsPerSecond,
            investor.totalRoiPlan2Invest,
            investor.actualRoiPlan2Inv,
            investor.roiPlan2DivsPerSecond,
            investor.endRoiPlan2PayDateTime,
            investor.totalRoiPlan3Invest,
            investor.actualRoiPlan3Inv
        );
    }
    function getInvestorPlansP2() view external returns(
                    uint128 roiPlan3DivsPerSecond,
                    uint128 endRoiPlan3PayDateTime,
                    uint64 totalRoiPlan4Invest,
                    uint64 actualRoiPlan4Inv,
                    uint128 roiPlan4DivsPerSecond,
                    uint128 endRoiPlan4PayDateTime,
                    uint64 lastRoiWidrawDateTime,
                    uint128 totalWithdraw
                    ) {
        Invest memory investor = invests[actualGameRun][msg.sender];
        return(
            investor.roiPlan3DivsPerSecond,
            investor.endRoiPlan3PayDateTime,
            investor.totalRoiPlan4Invest,
            investor.actualRoiPlan4Inv,
            investor.roiPlan4DivsPerSecond,
            investor.endRoiPlan4PayDateTime,
            investor.lastRoiWidrawDateTime,
            investor.totalWithdraw
        );
    }
    function getContractInfo() view external returns(uint16 _actualGameRun, 
                    uint64 _gameStarted, 
                    uint256 _grantTotalInvested, 
                    uint256 _totalInvested, 
                    uint32 _totalInvestors, 
                    uint32 _totalInvestings,
                    uint64 _maxInvestPlan2,
                    uint64 _maxInvestPlan3,
                    uint64 _maxInvestPlan4) {
        return(actualGameRun, 
            gameStarted, 
            grantTotalInvested, 
            totalInvested, 
            totalInvestors, 
            totalInvestings,
            maxInvestPlan2,
            maxInvestPlan3,
            maxInvestPlan4
        );
    }
    function getPorcentsInfo() view external returns
        (uint256 _porcentPlan1, uint256 _porcentPlan2, uint256 _porcentPlan3, uint256 _porcentPlan4)  {
        return(porcentPlan1, porcentPlan2, porcentPlan3, porcentPlan4);
    }
    function newOwner(address _address) public onlyOwner {
        owner = _address;
    }
    function newWhaletOwner(address payable _address) public onlyOwner {
        ownerWallet = _address;
    }
    function setMaxsInvest(uint64 _maxInvestPlan2, uint64 _maxInvestPlan3, uint64 _maxInvestPlan4) public onlyOwner {
        maxInvestPlan2 = _maxInvestPlan2;
        maxInvestPlan3 = _maxInvestPlan3;
        maxInvestPlan4 = _maxInvestPlan4;
    }
    function setPorcents(uint256 _porcentPlan1, uint256 _porcentPlan2, uint256 _porcentPlan3, uint256 _porcentPlan4, uint16 _daysForPlan2, uint16 _daysForPlan3, uint16 _daysForPlan4) public onlyOwner {
        if(gameStarted >= now) {
            porcentPlan1 = _porcentPlan1;
            porcentPlan2 = _porcentPlan2;
            porcentPlan3 = _porcentPlan3;
            porcentPlan4 = _porcentPlan4;
            daysForPlan2 = _daysForPlan2;
            daysForPlan3 = _daysForPlan3;
            daysForPlan4 = _daysForPlan4;
        }
    }
}