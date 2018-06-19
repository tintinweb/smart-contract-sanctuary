pragma solidity ^0.4.19;

contract LotteryRecharge
{
    address private contractAddress;
    uint256 public nPlatCurTotalEth;            // calculate all Recharges to contractAddress, unit wei
    uint256 public constant nCanOpenRewardMinEth = 10 ether;
    uint256 private constant leastRecharge = 0.1 ether;          // 100000000000000000 wei
    uint256 private constant OpenRewardClockSeconds = 1*3600;    // no permit greater than 24 * 3600
    uint256 private constant MaxClockSeconds = 24*3600;          // means 24*3600
    uint256 private constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    
    address public constant OfficialWalletAddr = 0x12961096767E28fFEB63180B83e946F45D16c4f8;
    
    // find player recharge at this contract, key=address,value=uint256
    mapping(address => uint256) private mapSenderAddr2Recharge;
    address[]  private ArrayAddress;
    uint256 public LatestRechargeTime;

    // contract construct function
    function LotteryRecharge() public
    {
        contractAddress = this;
    }

    function () public payable
    {
        transfer(contractAddress, msg.value);
    }
    
    function transfer(address _to, uint256 _value) private returns (bool bTranferSuccess)
    {
        require( _to != address(0) && (_to == contractAddress) && (_value >= leastRecharge));
        uint256 nRetFlag = CheckTime(OpenRewardClockSeconds);
        
        require(nRetFlag != 1);     //1 means can not open reward and recharge
        if( (nRetFlag == 2 ) && (IsCanAllotAward() == true)) 
        {
            // open reward time
            AllotAward();
        }
        return transferToContractAddr(_to, _value);
    }

    event TransferToContractAddrEvent(address _from, address _to, uint256 nValue, bytes _dataRet);
    function transferToContractAddr(address _to, uint256 _value) private returns (bool success)
    {
        require(_to != address(0) );
        require(mapSenderAddr2Recharge[msg.sender] <= MAX_UINT256 - _value);
        if(mapSenderAddr2Recharge[msg.sender] == 0)
        {
            ArrayAddress.push(msg.sender);
        }

        bytes memory empty;
        mapSenderAddr2Recharge[msg.sender] += _value;
        nPlatCurTotalEth += _value;
        LatestRechargeTime = now;
        TransferToContractAddrEvent(msg.sender, _to, _value, empty);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance)
    {
        require(_owner != address(0) );
        return mapSenderAddr2Recharge[_owner];
    }

    function IsCanAllotAward() private constant returns(bool CanAllotAward)
    {
        if (nPlatCurTotalEth >= nCanOpenRewardMinEth)
        {
            return true;
        }
        return false;
    }

    event AllotAwardEvent(bool AllotAwardSuccess);
    function AllotAward() private returns(bool AllotAwardSuccess)
    {
        require(nPlatCurTotalEth >= nCanOpenRewardMinEth);
        bytes32 byteHashValue = block.blockhash(block.number-1);
        uint256 nIntHash = uint256(byteHashValue);
        uint256 nRandomValue= (nIntHash + now) % (nPlatCurTotalEth);

        uint256 nSum = 0;
        for(uint256 i = 0; i < ArrayAddress.length; i++)
        {
            if( nSum <= nRandomValue && nRandomValue < nSum + mapSenderAddr2Recharge[ArrayAddress[i]] )
            {
                uint256 nOfficalGetEth = nPlatCurTotalEth/10;
                uint256 nParticipantGetEth = nPlatCurTotalEth - nOfficalGetEth;

                OfficialWalletAddr.transfer(nOfficalGetEth);
                ArrayAddress[i].transfer(nParticipantGetEth);

                for(uint256 j = 0; j < ArrayAddress.length; j++)
                {   //clear mapping
                    mapSenderAddr2Recharge[ArrayAddress[j] ]= 0;
                }
                LatestRechargeTime = 0;
                nPlatCurTotalEth = 0;
                ArrayAddress.length = 0;
                AllotAwardEvent(true);
                return true;
            }
            nSum += mapSenderAddr2Recharge[ArrayAddress[i]];
        }
    }

    function CheckTime(uint256 startTimeSeconds) private constant returns(uint256 nFlag)
    {
        if( LatestRechargeTime != 0 && (now % MaxClockSeconds > OpenRewardClockSeconds || (LatestRechargeTime + (MaxClockSeconds-OpenRewardClockSeconds) + 300 <= now)) )
        {
            //open reward time
            return 2;
        }
        else if ( (startTimeSeconds <= (now % MaxClockSeconds + 300) ) && (now % MaxClockSeconds <= startTimeSeconds ) )
        {
            //no permit recharge
            return 1;
        }
        //recharge time
        return 3;
    }
}