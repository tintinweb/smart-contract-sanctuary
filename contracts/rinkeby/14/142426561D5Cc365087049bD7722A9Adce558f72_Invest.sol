// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./PoolsData.sol";
import "./SafeMath.sol";
import "./ISolCloutBenefit.sol";
import "./ILockedDeal.sol";

contract Invest is PoolsData {
    event NewInvestorEvent(uint256 Investor_ID, address Investor_Address, uint256 LockedDeal_ID);

    modifier CheckTime(uint256 _Time) {
        require(block.timestamp >= _Time, "Pool not open yet");
        _;
    }

    modifier validateSender(){
        require(
            msg.sender == tx.origin && !isContract(msg.sender),
            "Some thing wrong with the msgSender"
        );
        _;
    }

    //using SafeMath for uint256;
    constructor() {
        //TotalInvestors = 0;
    }
    
    uint256 participants;
    mapping(uint256 => TotalParticipantsInPool) public Participant;
    struct TotalParticipantsInPool{
        uint256 participantsCount;
    }

    //Investorsr Data
    uint256 internal TotalInvestors;
    mapping(uint256 => Investor) Investors;
    mapping(address => uint256[]) InvestorsMap;
    
    mapping(address => Investor) public yourAllocation;
    
    struct Investor {
        uint256 Poolid; //the id of the pool, he got the rate info and the token, check if looked pool
        address InvestorAddress; //
        uint256 MainCoin; //the amount of the main coin invested (eth/dai), calc with rate
        uint256 InvestTime; //the time that investment made
        uint256 TotalTokens;
    }

    function getTotalInvestor() external view returns(uint256){
        return TotalInvestors;
    }
    
    function yourInvestment(uint256 _PoolId)
        public
        view 
        returns(
            uint256 _InvestedAmount,
            uint256 _TimeOfInvestment,
            uint256 _TotalTokens
        )
    {
        for(uint i = 0; i< TotalInvestors; i++){
            Investor storage investor = Investors[i];
            if(investor.Poolid == _PoolId && investor.InvestorAddress == msg.sender){
                // uint256 InvestedAmount = investor.MainCoin;
                // uint256 TimeOfInvestment = investor.InvestTime;
                // uint256 TotalToken = investor.TotalTokens;
                return (investor.MainCoin, investor.InvestTime, investor.TotalTokens);
            }
        }
    }
    
    //@dev Send in wei
    function InvestETH(uint256 _PoolId)
        external
        payable
        ReceivETH(msg.value, msg.sender, MinETHInvest)
        whenNotPaused
        CheckTime(pools[_PoolId].MoreData.StartTime)
        isPoolId(_PoolId)
        validateSender()
    {
        require(pools[_PoolId].BaseData.Maincoin == address(0x0), "Pool is only for ETH");
        // uint256 ThisInvestor = NewInvestor(msg.sender, msg.value, _PoolId);
        uint256 Tokens = CalcTokens(_PoolId, msg.value, msg.sender);
        
        for(uint i = 0; i< TotalInvestors; i++){
            Investor storage investor = Investors[i];
            if(investor.Poolid == _PoolId && investor.InvestorAddress == msg.sender){
                investor.MainCoin = SafeMath.add(investor.MainCoin, msg.value);
                investor.TotalTokens = SafeMath.add(investor.TotalTokens, Tokens);
            }
        }
    
        Participant[_PoolId] = TotalParticipantsInPool(SafeMath.add(Participant[_PoolId].participantsCount, 1)) ;
        
        yourAllocation[msg.sender] = Investor(_PoolId, msg.sender, msg.value, block.timestamp, Tokens);
        
        uint256 ThisInvestor = NewInvestor(msg.sender, msg.value, _PoolId, Tokens);
        
        TokenAllocate(_PoolId, ThisInvestor, Tokens);

        uint256 EthMinusFee =
            SafeMath.div(
                SafeMath.mul(msg.value, SafeMath.sub(10000, CalcFee(_PoolId))),
                10000
            );
        // send money to project owner - the fee stays on contract
        TransferETH(payable(pools[_PoolId].BaseData.Creator), EthMinusFee); 
        RegisterInvest(_PoolId, Tokens);
    }

    function InvestERC20(uint256 _PoolId, uint256 _Amount)
        external
        whenNotPaused
        CheckTime(pools[_PoolId].MoreData.StartTime)
        isPoolId(_PoolId)
        validateSender()
    {
        require(
            pools[_PoolId].BaseData.Maincoin != address(0x0),
            "Pool is for ETH, use InvestETH"
        );
        TransferInToken(pools[_PoolId].BaseData.Maincoin, msg.sender, _Amount);
        uint256 Tokens = CalcTokens(_PoolId, _Amount, msg.sender);
        
        for(uint i = 0; i< TotalInvestors; i++){
            Investor storage investor = Investors[i];
            if(investor.Poolid == _PoolId && investor.InvestorAddress == msg.sender){
                investor.MainCoin = SafeMath.add(investor.MainCoin, _Amount);
                investor.TotalTokens = SafeMath.add(investor.TotalTokens, Tokens);
            }
        }
        
        Participant[_PoolId] = TotalParticipantsInPool(SafeMath.add(Participant[_PoolId].participantsCount, 1)) ;
        
        uint256 ThisInvestor = NewInvestor(msg.sender, _Amount, _PoolId, Tokens);
        
        TokenAllocate(_PoolId, ThisInvestor, Tokens);

        uint256 RegularFeePay =
            SafeMath.div(SafeMath.mul(_Amount, CalcFee(_PoolId)), 10000);

        uint256 RegularPaymentMinusFee = SafeMath.sub(_Amount, RegularFeePay);
        FeeMap[pools[_PoolId].BaseData.Maincoin] = SafeMath.add(
            FeeMap[pools[_PoolId].BaseData.Maincoin],
            RegularFeePay
        );
        TransferToken(
            pools[_PoolId].BaseData.Maincoin,
            pools[_PoolId].BaseData.Creator,
            RegularPaymentMinusFee
        ); // send money to project owner - the fee stays on contract
        RegisterInvest(_PoolId, Tokens);
    }

    function TokenAllocate(uint256 _PoolId, uint256 _ThisInvestor, uint256 _Tokens) internal {
        uint256 lockedDealId;
        if (isPoolLocked(_PoolId)) {
            require(isUsingLockedDeal(), "Cannot invest in TLP without LockedDeal");
            (address tokenAddress,,,,,) = GetPoolBaseData(_PoolId);
            (uint64 lockedUntil,,,,,) = GetPoolMoreData(_PoolId);
            ApproveAllowanceERC20(tokenAddress, LockedDealAddress, _Tokens);
            lockedDealId = ILockedDeal(LockedDealAddress).CreateNewPool(tokenAddress, lockedUntil, _Tokens, msg.sender);
        } else {
            // not locked, will transfer the tokens
            TransferToken(pools[_PoolId].BaseData.Token, Investors[_ThisInvestor].InvestorAddress, _Tokens);
        }
        emit NewInvestorEvent(_ThisInvestor, Investors[_ThisInvestor].InvestorAddress, lockedDealId);
    }

    function RegisterInvest(uint256 _PoolId, uint256 _Tokens) internal {
        pools[_PoolId].MoreData.Lefttokens = SafeMath.sub(
            pools[_PoolId].MoreData.Lefttokens,
            _Tokens
        );
        if (pools[_PoolId].MoreData.Lefttokens == 0) emit FinishPool(_PoolId);
        else emit PoolUpdate(_PoolId);
    }

    function NewInvestor(
        address _Sender,
        uint256 _Amount,
        uint256 _Pid,
        uint256 _Tokens
    ) internal returns (uint256) {
        Investors[TotalInvestors] = Investor(
            _Pid,
            _Sender,
            _Amount,
            block.timestamp,
            _Tokens
        );
        InvestorsMap[msg.sender].push(TotalInvestors);
        TotalInvestors = SafeMath.add(TotalInvestors, 1);
        return SafeMath.sub(TotalInvestors, 1);
    }

    function CalcTokens(
        uint256 _Pid,
        uint256 _Amount,
        address _Sender
    ) internal returns (uint256) {
        uint256 msgValue = _Amount;
        uint256 result = 0;
        if (GetPoolStatus(_Pid) == PoolStatus.Created) {
            require(VerifySolCloutHolding(_Sender), "Only SOLC holder can invest");
            IsWhiteList(_Sender, pools[_Pid].MoreData.WhiteListId, _Amount);
            result = SafeMath.mul(msgValue, pools[_Pid].BaseData.SOLCRate);
            return result;
        }
        if (GetPoolStatus(_Pid) == PoolStatus.Open) {
            IsWhiteList(_Sender, pools[_Pid].MoreData.WhiteListId, _Amount);
            (,,address _mainCoin) = GetPoolExtraData(_Pid);
            if(_mainCoin == address(0x0)){
                require(
                    msgValue >= MinETHInvest && msgValue <= MaxETHInvest,
                    "Investment amount not valid"
                );
            } else {
                require(
                    msgValue >= MinERC20Invest && msgValue <= MaxERC20Invest,
                    "Investment amount not valid"
                );
            }
            LastRegisterWhitelist(_Sender, pools[_Pid].MoreData.WhiteListId);
            result = SafeMath.mul(msgValue, pools[_Pid].BaseData.Rate);
            return result;
        }
        if (result >= 10**21) {
            if (pools[_Pid].MoreData.Is21DecimalRate) {
                result = SafeMath.div(result, 10**21);
            }
            require(
                result <= pools[_Pid].MoreData.Lefttokens,
                "Not enough tokens in the pool"
            );
            return result;
        }
        revert("Wrong pool status to CalcTokens");
    }

    function VerifySolCloutHolding(address _Sender) internal view returns(bool){
        if(Benefit_Address == address(0)) return true;
        return ISolCloutBenefit(Benefit_Address).IsSOLCHolder(_Sender);
    }

    function LastRegisterWhitelist(address _Sender,uint256 _Id) internal returns(bool) {
        if (_Id == 0) return true; //turn-off
        IWhiteList(WhiteList_Address).LastRoundRegister(_Sender, _Id);
        return true;
    }

    function CalcFee(uint256 _Pid) internal view returns (uint256 _fee) {
        if (GetPoolStatus(_Pid) == PoolStatus.Created) {
            return SOLCFee;
        }
        if (GetPoolStatus(_Pid) == PoolStatus.Open) {
            return Fee;
        }
    }

    //@dev use it with  require(msg.sender == tx.origin)
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    //  no need register - will return true or false base on Check
    //  if need register - revert or true
    function IsWhiteList(
        address _Investor,
        uint256 _Id,
        uint256 _Amount
    ) internal returns (bool) {
        if (_Id == 0) return true; //turn-off
        IWhiteList(WhiteList_Address).Register(_Investor, _Id, _Amount); //will revert if fail
        return true;
    }
}