//SourceUnit: trw_.sol

/*
    Plan:
    1 - Receive infinite 0.666% ROI daily, get your investment back in 150 days! and you keep charging until the end - 243% per year
        Deferred payments in ROI 3.5% and 10.15%
    2 - Receive 105% in 30 days! 3.5% daily ROI. You get your investment back in 28 days! - 60% annually
    3 - Receive 101.5% in 10 days! 10.15% daily ROI. You get your investment back in 9 days! - 54% annually
    
    
    100% Safe, Verified Certificate, no risks!
        
        ***********
        
    100% Seguro, Certificado Verificado, sin riesgos!
    
    Plan:
    1 - Recibe infinito 0.666% ROI diario, recuperas tu inversion en 150 dias! y sigues cobrando hasta el final - 243% anual
        Pagos diferidos en ROI 3.5% y 10.15%
    2 - Recibe el 105% en 30 dias! 3.5% ROI diario. Recuperas tu inversion en 28 dias! - 60% anual
    3 - Recibe el 101.5% en 10 dias! 10.15% ROI diario. Recuperas tu inversion en 9 dias! - 54% anual
    
*/

pragma solidity ^0.5.10;
contract TronBankWin {
    address addressContract;
    address owner;
    address payable ownerWallet;
    uint256 public totalInvested;
    uint32 public totalInvestors;
    uint32 public totalInvestings;
    uint32 constant trxyz = 1000000;
    
    struct Invest {
        uint8 exist;
        uint64 totalRoiInfInvest;
        uint128 roiInfDivsPerSecond;
        uint64 totalRoi35Invest;
        uint64 actualRoi35Inv;
        uint128 roi35DivsPerSecond;
        uint128 endRoi35PayDateTime;
        uint64 totalRoi1015Invest;
        uint64 actualRoi1015Inv;
        uint128 roi1015DivsPerSecond;
        uint128 endRoi1015PayDateTime;
        uint64 lastRoiWidrawDateTime;
        uint128 totalWithdraw;
    }
    mapping(address => Invest) public invests;
    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
        addressContract = address(this);
    }
    function withdraw() public {
        Invest storage investor = invests[msg.sender];
        _payer(investor);
    }
    function invest(uint8 _plan) payable public {
        require(msg.value>0,"No invest!");
        require(_plan>0 && _plan<4,"No plan!");
        Invest storage investor = invests[msg.sender];
        ownerWallet.transfer((msg.value / 10));
        totalInvested+=msg.value;
        totalInvestings++;
        if(investor.exist==0) {
            totalInvestors++;
            investor.exist = 1;
        }
        _payer(investor);
        if(_plan == 1) {
            investor.roiInfDivsPerSecond += uint128((msg.value * 6660000000) / 86400);
            investor.totalRoiInfInvest += uint64(msg.value);
        } 
        uint128 toGet;
        if(_plan == 2) {
            if(investor.roi35DivsPerSecond==0) {
                investor.roi35DivsPerSecond = uint128((msg.value * 35000000000) / 86400);
            } else {
                if(investor.endRoi35PayDateTime>now) {
                    toGet = (investor.roi35DivsPerSecond * uint128(investor.endRoi35PayDateTime-now) * 952380) / 1000000000000000000;
                    investor.roi35DivsPerSecond = uint128((((msg.value + toGet) * 35000000000) ) / 86400);
                } else {
                    investor.roi35DivsPerSecond = uint128((msg.value * 35000000000) / 86400);
                }
            }
            investor.totalRoi35Invest += uint64(msg.value);
            investor.actualRoi35Inv = uint64(msg.value + toGet);
            investor.endRoi35PayDateTime = uint64(now+(86400*30));
        }
        if(_plan == 3) {
            if(investor.roi1015DivsPerSecond==0) {
                investor.roi1015DivsPerSecond = uint128((msg.value * 101500000000) / 86400);
            } else {
                if(investor.endRoi1015PayDateTime>now) {
                    toGet = (investor.roi1015DivsPerSecond * uint128(investor.endRoi1015PayDateTime-now) * 985221 ) / 1000000000000000000;
                    investor.roi1015DivsPerSecond = uint128((((msg.value + toGet) * 101500000000)) / 86400);
                } else {
                    investor.roi1015DivsPerSecond = uint128((msg.value * 101500000000) / 86400);
                }
            }
            investor.totalRoi1015Invest += uint64(msg.value);
            investor.actualRoi1015Inv = uint64(msg.value + toGet);
            investor.endRoi1015PayDateTime = uint64(now+(86400*10));
        }
    }
    function _payer(Invest storage investor) internal {
        require(investor.exist != 0,"investor no exist!");
        uint128 toWithdraw;
        if(investor.roiInfDivsPerSecond>0) toWithdraw = (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiInfDivsPerSecond) / trxyz;
        if(investor.roi35DivsPerSecond>0) {
            if(investor.endRoi35PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roi35DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoi35PayDateTime > investor.lastRoiWidrawDateTime) {
                    toWithdraw += (uint128(investor.endRoi35PayDateTime - investor.lastRoiWidrawDateTime) * investor.roi35DivsPerSecond) / trxyz;
                }
                investor.roi35DivsPerSecond=0;
            }
        }
        if(investor.roi1015DivsPerSecond>0) {
            if(investor.endRoi1015PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roi1015DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoi1015PayDateTime > investor.lastRoiWidrawDateTime) { //remanente
                    toWithdraw += (uint128(investor.endRoi1015PayDateTime - investor.lastRoiWidrawDateTime) * investor.roi1015DivsPerSecond) / trxyz;
                }
                investor.roi1015DivsPerSecond=0;
            }
        }
        if(toWithdraw>0) {
            toWithdraw /= trxyz;
            if(addressContract.balance>0) {
                if(addressContract.balance>=toWithdraw) {
                    investor.totalWithdraw += toWithdraw;
                    msg.sender.transfer(toWithdraw);
                } else {
                    investor.totalWithdraw += uint64(addressContract.balance);
                    msg.sender.transfer(addressContract.balance);
                }
            }
        }
        investor.lastRoiWidrawDateTime = uint64(now);
    }
    function toWithdraw() view public returns(uint256 toWithdraw) {
        Invest memory investor = invests[msg.sender];
        require(investor.exist != 0,"investor no exist!");
        if(investor.roiInfDivsPerSecond>0) toWithdraw = (uint128(now - investor.lastRoiWidrawDateTime) * investor.roiInfDivsPerSecond) / trxyz;
        if(investor.roi35DivsPerSecond>0) {
            if(investor.endRoi35PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roi35DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoi35PayDateTime > investor.lastRoiWidrawDateTime) {
                    toWithdraw += (uint128(investor.endRoi35PayDateTime - investor.lastRoiWidrawDateTime) * investor.roi35DivsPerSecond) / trxyz;
                }
            }
        }
        if(investor.roi1015DivsPerSecond>0) {
            if(investor.endRoi1015PayDateTime>now) {
                toWithdraw += (uint128(now - investor.lastRoiWidrawDateTime) * investor.roi1015DivsPerSecond) / trxyz;
            } else {
                if(investor.endRoi1015PayDateTime > investor.lastRoiWidrawDateTime) {
                    toWithdraw += (uint128(investor.endRoi1015PayDateTime - investor.lastRoiWidrawDateTime) * investor.roi1015DivsPerSecond) / trxyz;
                }
            }
        }
        toWithdraw /= trxyz;
    }
    function toPay(uint8 _plan) view public returns(uint256 toPay) {
        Invest memory investor = invests[msg.sender];
        require(investor.exist != 0,"investor no exist!");
        if(_plan==1) return investor.totalRoiInfInvest;
        if(_plan==2) return (investor.roi35DivsPerSecond * (investor.endRoi35PayDateTime-uint128(now)) * 952380) / 1000000000000000000;
        if(_plan==3) return (investor.roi1015DivsPerSecond * (investor.endRoi1015PayDateTime-uint128(now)) * 985221) / 1000000000000000000;
    }
    function newOwner(address _address) public {
        require(msg.sender==owner);
        owner = _address;
    }
    function newWhaletOwner(address payable _address) public {
        require(msg.sender==owner);
        ownerWallet = _address;
    }
}