pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract Moho is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Moho Basis
    uint256 private cdTime;
    uint256 private payJoinAmount;
    Invite private inviteContract;
    ERC20 private usdtTokenContract;
    ERC20 private dtuTokenContract;
    ERC20 private spiritFragmentContract;
    address private unionPoolAddress;// 50%
    address private developmentFundAddress;// 5%
    address private oraclePairDtuAddress;
    bool private switchState;
    uint256 private startTime;
    uint256 private nowJoinTotalCount;
    uint256 private nowOutSpiritFragment;

    // wheel
    uint256 private wheelTotal = 10;
    uint256 private wheelMaxWin = 1;
    uint256 private wheelNowWin = 0;
    uint256 private wheelCount = 1;
    uint256 private randNonce = 0;

    // Account
    mapping(address => MohoAccount) private mohoAccounts;
    struct MohoAccount {
        uint256 totalJoinCount;
        uint256 lastMohoTime;
        uint256 canMohoTime;
        uint256 winningCount;
        uint256 canClaimAmount;
        uint256 [] ordersIndex;
    }
    mapping(uint256 => MohoOrder) private mohoOrders;
    struct MohoOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        bool isWinning;
    }

    // Events
    event SedimentToken(address indexed _account, address _erc20TokenContract, address _to, uint256 _amount);
    event SetMohoBasis(address indexed _account, uint256 _cdTime, uint256 _payJoinAmount);
    event AddressList(address indexed _account, address _inviteContract, address _usdtTokenContract, address _spiritFragmentContract, address _unionPoolAddress, address _developmentFundAddress, address _dtuTokenContract, address _oraclePairDtuAddress);
    event SetSwitchState(address indexed _account, bool _switchState);
    event JoinMoho(address indexed _account, uint256 _nowJoinTotalCount, bool _isWinning, uint256 _random);
    event ClaimMoho(address indexed _account, uint256 _userClaimAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* cdTime = 1800; */
          cdTime = 120;
          payJoinAmount = 100 * 10 ** 18;// 100 Token
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          usdtTokenContract = ERC20(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
          spiritFragmentContract = ERC20(0xbd2905f857Ac3Fd20D741e68efb4445831bd77D7);
          unionPoolAddress = address(0x13e4A8ddB241AF74846f341dE2A506fdc6646748);
          developmentFundAddress = address(0x4952cE6E663a19eB58109f65419ED09aeE904b0B);
          oraclePairDtuAddress = address(0x72783C370f41117822de2A214C42Fe39fdFAD748);
          switchState = true;
    }

    // ================= Moho Operation  =====================

    function getOraclePairDtuUsdt() public view returns (uint256) {
        uint256 pairDtu = dtuTokenContract.balanceOf(oraclePairDtuAddress);
        uint256 pairUsdt = usdtTokenContract.balanceOf(oraclePairDtuAddress);
        return pairDtu.mul(1000000).div(pairUsdt);
    }

    function claimMoho(uint256 _userClaimAmount) public returns (bool) {
        // Data validation
        uint256 canClaimAmount = mohoAccounts[msg.sender].canClaimAmount;
        require(_userClaimAmount<=canClaimAmount,"-> canClaimAmount: The amount of withdrawable income is 0.");

        uint256 payDtuAmount = _userClaimAmount.div(2).mul(getOraclePairDtuUsdt()).div(1000000);
        require(dtuTokenContract.balanceOf(msg.sender)>=payDtuAmount,"-> payDtuAmount: Insufficient address dtu balance.");

        // Transfer
        dtuTokenContract.safeTransferFrom(address(msg.sender),address(this),payDtuAmount);// dtu to this
        usdtTokenContract.safeTransfer(address(msg.sender), _userClaimAmount);// Transfer _userClaimAmount to moho Address

        // Orders dispose
        mohoAccounts[msg.sender].canClaimAmount -= _userClaimAmount;

        emit ClaimMoho(msg.sender, _userClaimAmount);
        return true;
    }

    function joinMoho() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(switchState,"-> switchState: Moho is not enabled.");
        require(block.timestamp>=mohoAccounts[msg.sender].canMohoTime,"-> canMohoTime: The next moho time is not reached.");
        require(usdtTokenContract.balanceOf(msg.sender)>=payJoinAmount,"-> payJoinAmount: Insufficient address usdt balance.");

        // Transfer
        usdtTokenContract.safeTransferFrom(address(msg.sender),address(this),payJoinAmount);// usdt to this

        // Winning calculation
        uint256 random;
        bool isWinning;
        if(wheelTotal<=0){
            wheelTotal = 9; wheelCount += 1; wheelNowWin = 0;
        }else{
            wheelTotal -= 1;
        }

        if(wheelMaxWin == wheelNowWin){
            isWinning = false;//must false
        }else if(wheelMaxWin-wheelNowWin>wheelTotal){
            isWinning = true;// must true
        }else{
           random = randomNumber();
           random = block.timestamp.add(random);
           random = random.mod(10);
           if(random >= 9){     // 10%
              isWinning = true; wheelNowWin += 1;
           }else{
              isWinning = false;
           }
        }

        // isWinning == true
        if(isWinning){
            mohoAccounts[msg.sender].winningCount += 1;
            nowOutSpiritFragment += 1;

            // Transfer
            usdtTokenContract.safeTransfer(unionPoolAddress, payJoinAmount.div(2));// Transfer 50% to unionPoolAddress Address
            usdtTokenContract.safeTransfer(developmentFundAddress, payJoinAmount.div(20));// Transfer 5% to developmentFundAddress Address
            spiritFragmentContract.safeTransfer(address(msg.sender), 1);// Transfer fragment to moho address
        }
        // isWinning == true
        else{
            // Transfer
            usdtTokenContract.safeTransfer(address(msg.sender), payJoinAmount);// Transfer 100% to moho Address
            mohoAccounts[msg.sender].canClaimAmount += payJoinAmount.div(20);// Non winning award
        }

        // Orders dispose
        nowJoinTotalCount += 1;
        mohoAccounts[msg.sender].totalJoinCount += 1;
        mohoAccounts[msg.sender].lastMohoTime = block.timestamp;
        mohoAccounts[msg.sender].canMohoTime = block.timestamp.add(cdTime);
        mohoAccounts[msg.sender].ordersIndex.push(nowJoinTotalCount);// add mohoAccounts
        mohoOrders[nowJoinTotalCount] = MohoOrder(nowJoinTotalCount,msg.sender,block.timestamp,isWinning);// add mohoOrders

        emit JoinMoho(msg.sender, nowJoinTotalCount, isWinning, random);
        return true;
    }

    // ================= Contact Query  =====================

    function getMohoBasic() public view returns (uint256 CdTime,uint256 PayJoinAmount,Invite InviteContract,ERC20 UsdtTokenContract,ERC20 SpiritFragmentContract,address UnionPoolAddress,address DevelopmentFundAddress,
      ERC20 DtuTokenContract,address OraclePairDtuAddress,bool SwitchState,uint256 StartTime,uint256 NowJoinTotalCount,uint256 NowOutSpiritFragment) {
        return (cdTime,payJoinAmount,inviteContract,usdtTokenContract,spiritFragmentContract,unionPoolAddress,developmentFundAddress,dtuTokenContract,oraclePairDtuAddress,switchState,startTime,nowJoinTotalCount,nowOutSpiritFragment);
    }

    function mohoAccountsOf(address _account) public view returns (uint256 TotalJoinCount,uint256 LastMohoTime,uint256 CanMohoTime,uint256 WinningCount,uint256 CanClaimAmount,uint256 [] memory OrdersIndex){
        MohoAccount storage account =  mohoAccounts[_account];
        return (account.totalJoinCount,account.lastMohoTime,account.canMohoTime,account.winningCount,account.canClaimAmount,account.ordersIndex);
    }

    function mohoOrdersOf(uint256 _joinOrderIndex) public view returns (uint256 Index,address Account,uint256 JoinTime,bool IsWinning){
        MohoOrder storage order =  mohoOrders[_joinOrderIndex];
        return (order.index,order.account,order.joinTime,order.isWinning);
    }

    function getMohoWheel() public view returns (uint256 WheelCount,uint256 WheelTotal,uint256 WheelNowWin,uint256 WheelMaxWin,uint256 RandNonce){
        return (wheelCount,wheelTotal,wheelNowWin,wheelMaxWin,randNonce);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _usdtTokenContract,address _spiritFragmentContract,address _unionPoolAddress,address _developmentFundAddress,
      address _dtuTokenContract,address _oraclePairDtuAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        usdtTokenContract = ERC20(_usdtTokenContract);
        spiritFragmentContract = ERC20(_spiritFragmentContract);
        unionPoolAddress = _unionPoolAddress;
        developmentFundAddress = _developmentFundAddress;
        dtuTokenContract = ERC20(_dtuTokenContract);
        oraclePairDtuAddress = _oraclePairDtuAddress;
        emit AddressList(msg.sender, _inviteContract, _usdtTokenContract, _spiritFragmentContract, _unionPoolAddress, _developmentFundAddress,_dtuTokenContract,_oraclePairDtuAddress);
        return true;
    }

    function setSwapSwitchState(bool _switchState) public onlyOwner returns (bool) {
        switchState = _switchState;
        if(startTime==0&&switchState){
            startTime = block.timestamp;
        }
        emit SetSwitchState(msg.sender, _switchState);
        return true;
    }

    function setMohoBasis(uint256 _cdTime,uint256 _payJoinAmount) public onlyOwner returns (bool) {
        cdTime = _cdTime;
        payJoinAmount = _payJoinAmount;
        emit SetMohoBasis(msg.sender, _cdTime, _payJoinAmount);
        return true;
    }

    // Random return 0-9 integer
    function randomNumber() private returns(uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10;
        randNonce++;
        return rand;
    }

}