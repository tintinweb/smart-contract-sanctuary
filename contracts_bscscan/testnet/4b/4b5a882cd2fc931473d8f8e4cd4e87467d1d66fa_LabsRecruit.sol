pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";

contract LabsRecruit is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // uint256 public boxTrxOne = 50000 * 10 ** decimals;// Define the amount of TRX recruited by the node
    uint256 private decimals = 6;
    uint256 public nodeTrxAmount = 5 * 10 ** decimals;
    uint256 public nodeMaxCount = 5;
    uint256 public nodeNowCount = 0;
    uint256 private joinGiveRea = 15 * 10 ** decimals;// Immediately to the account 5000*30%=1500 pieces
    uint256 private inviteGiveRea = 5 * 10 ** decimals;// Node Recommendation Revenue

    // Related address information
    ERC20 public usdtTokenContract;
    ERC20 public reaTokenContract;
    address public creationAddress;
    bool public labsRecruitSwitchState = false;
    uint256 public labsRecruitStartTime;
    uint256 private resultData;// Return 0 Successfully
    mapping(address => bool) public isJoinLabs;
    mapping(address => address) public inviteAddress;

    mapping(uint256 => address) private nodeAddressInfo;
    mapping(address => nodeGroupOrder) public nodeGroupOrders;
    struct nodeGroupOrder {
        uint256 index;
        bool isExist;
        uint256 joinLabsTime;
        uint256 reaFinalExtractTime;
        uint256 usdtFinalExtractTime;
        uint256 trxFinalExtractTime;
        uint256 reaAllEarnedIncome;
        uint256 usdtAllEarnedIncome;
        uint256 trxAllEarnedIncome;
        uint256 usdtExtractionYield;
        uint256 trxExtractionYield;
        uint256 reaExtractionYield;
    }
    uint256 public trxStatisticsTime;
    uint256 public usdtStatisticsTime;
    uint256 public reaStatisticsTime;
    uint256 public trxUnwithdrawnEarnings;
    uint256 public usdtUnwithdrawnEarnings;
    uint256 public reaUnwithdrawnEarnings;
    uint256 public joinLabsTrxBalance;// Number of wave fields added to nodes
    uint256 public preRechargeReaBalance;//Number of recharging rea
    mapping(address => uint256) public inviterRevenueRea;

    constructor(address _usdtTokenContract,address _reaTokenContract) public {
        usdtTokenContract = ERC20(_usdtTokenContract);
        reaTokenContract = ERC20(_reaTokenContract);
    }

    // Add event log
    event JoinLabs(address indexed account,address indexed inviteAddress,uint256 nodeTrxAmount,uint256 joinGiveRea,uint256 inviteGiveRea,uint256 nodeNowCount);
    event GetSedimentRea(address indexed account,address indexed to,uint256 num);
    event GetSedimentTrx(address indexed account,address indexed to,uint256 num);
    event GetSedimentUsdt(address indexed account,address indexed to,uint256 num);
    event NodeWithdrawTrx(address indexed account,uint256 num);
    event NodeWithdrawUsdt(address indexed account,uint256 num);
    event NodeWithdrawRea(address indexed account,uint256 num);
    event WeeklyIncomeStatisticsTrx(address indexed account,uint256 thisTrxNum,uint256 nodeNowCount,uint256 trxUnwithdrawnEarnings,uint256 callType);
    event WeeklyIncomeStatisticsUsdt(address indexed account,uint256 thisTrxNum,uint256 nodeNowCount,uint256 usdtUnwithdrawnEarnings,uint256 callType);
    event WeeklyIncomeStatisticsRea(address indexed account,uint256 thisTrxNum,uint256 nodeNowCount,uint256 reaUnwithdrawnEarnings,uint256 callType);
    event PreRechargeReaBalance(address indexed account,uint256 num);
    event FunctionRechargeRea(address indexed account,uint256 num);

    // Trx precipitated in the contract was extracted
    function getSedimentTrx(address to,uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract TRX balance is sufficient
        require(address(this).balance>=amount,"-> TRX: Insufficient balance of TRX available to contract.");
        require(joinLabsTrxBalance>=amount,"-> TRX: Only the part of join node can be extracted.");
        address(uint160(to)).transfer(amount);// Transfer trx to destination address
        joinLabsTrxBalance -= amount;
        emit GetSedimentTrx(msg.sender,to,amount);// set log
        return "getSedimentTrx success";// return result
    }
    // Number of recharging rea
    function preRechargeRea(uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract REA balance is sufficient
        require(reaTokenContract.balanceOf(address(this))>=amount,"-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        preRechargeReaBalance += amount;
        emit PreRechargeReaBalance(msg.sender,amount);// set log
        return "preRechargeReaBalance success";// return result
    }
    // Number of recharging rea
    function functionRechargeRea(uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract TRX balance is sufficient
        require(reaTokenContract.balanceOf(address(msg.sender))>=amount,"-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        // Transfer the user REA to the contract
        reaTokenContract.safeTransferFrom(address(msg.sender),address(this),amount);

        preRechargeReaBalance += amount;
        emit FunctionRechargeRea(msg.sender,amount);// set log
        return "functionRechargeRea success";// return result
    }
    // Rea precipitated in the contract was extracted
    function getSedimentRea(address to,uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract REA balance is sufficient
        require(reaTokenContract.balanceOf(address(this))>=amount,"-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        require(preRechargeReaBalance>=amount,"-> reaTokenContract: Only the part of join node can be extracted.");
        reaTokenContract.safeTransfer(to,amount);// Transfer rea to destination address
        preRechargeReaBalance -= amount;
        emit GetSedimentRea(msg.sender,to,amount);// set log
        return "getSedimentRea success";// return result
    }
    // Usdt precipitated in the contract was extracted
    function getSedimentUsdt(address to,uint256 amount) public onlyOwner returns (string memory result) {
        // Determine whether the contract USDT balance is sufficient
        require(usdtTokenContract.balanceOf(address(this))>=amount,"-> usdtTokenContract: Insufficient balance of USDT TOKEN available to contract.");
        usdtTokenContract.safeTransfer(to,amount);// Transfer usdt to destination address
        emit GetSedimentUsdt(msg.sender,to,amount);// set log
        return "getSedimentUsdt success";// return result
    }
    // Set the creation address to be used as the referrer for the first time to participate in the node
    function setCreationAddress(address _creationAddress) public onlyOwner {
        creationAddress = _creationAddress;
    }
    // Set the node switch state and update the node recruitment start time
    function setLabsRecruitSwitchState(bool _labsRecruitSwitchState) public onlyOwner {
        labsRecruitSwitchState = _labsRecruitSwitchState;
        labsRecruitStartTime = block.timestamp;// update labsRecruitStartTime
        trxStatisticsTime = block.timestamp;
        usdtStatisticsTime = block.timestamp;
        reaStatisticsTime = block.timestamp;
    }
    // Set the amount of node recruitment participation
    function setNodeTrxAmount(uint256 _nodeTrxAmount) public onlyOwner {
        nodeTrxAmount = _nodeTrxAmount;
    }
    // Add node business logic processing
    function joinLabs(address _inviteAddress) public payable returns (uint256 resultData) {
        require(labsRecruitSwitchState,"-> labsRecruitSwitchState: Node recruitment has not started yet.");
        require(msg.value>=nodeTrxAmount,"-> nodeTrxAmount: The TRX balance of the join node was not reached.");
        require(msg.value<=nodeTrxAmount.add(10),"-> nodeTrxAmount: You pay too much.");
        require(isJoinLabs[msg.sender]==false,"-> isJoinLabs: The address has become a node.");
        if(_inviteAddress!=creationAddress){
            require(isJoinLabs[_inviteAddress]==true,"-> _inviteAddress: The inviter is not a creator or node person address.");
        }
        require(nodeNowCount<nodeMaxCount,"-> nodeMaxCount: The maximum number of nodes that can be added has been reached.");

        inviteAddress[msg.sender] = _inviteAddress; // Write invitation relationship
        isJoinLabs[msg.sender] = true; // Added node successfully
        nodeNowCount += uint256(1);// Current number of added nodes +1
        joinLabsTrxBalance += nodeTrxAmount;

        preRechargeReaBalance -= joinGiveRea.add(inviteGiveRea);// When you join a node, the reward itself and the reward recommender consume the pre recharge value
        inviterRevenueRea[_inviteAddress] += inviteGiveRea;// Income statistics of invitees

        // Immediately to the account 5000*30%=1500 pieces + Node Recommendation Revenue 500 REA
        require(reaTokenContract.balanceOf(address(this))>=joinGiveRea.add(inviteGiveRea),"-> reaTokenContract: Insufficient balance of REA TOKEN available to contract.");
        reaTokenContract.safeTransfer(msg.sender,joinGiveRea);// Transfer rea to joinGiveRea address
        reaTokenContract.safeTransfer(_inviteAddress,inviteGiveRea);// Transfer rea to inviteGiveRea address
        emit JoinLabs(msg.sender,_inviteAddress,nodeTrxAmount,joinGiveRea,inviteGiveRea,nodeNowCount);// set log

        // Write node group
        nodeAddressInfo[nodeNowCount] = msg.sender;
        nodeGroupOrders[msg.sender] = nodeGroupOrder(nodeNowCount,true,block.timestamp,block.timestamp,block.timestamp,block.timestamp,uint256(0),uint256(0),uint256(0),uint256(0),uint256(0),uint256(0));

        return resultData;
    }
    // Node withdrawal last week's earnings TRX
    function nodeWithdrawTRX() public returns (string memory result) {
        // Enable statistics or not
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(trxStatisticsTime);
        if(diff>600){// The user calls
              uint256 countDay = diff.div(600);
              // Determine whether the contract TRX balance is sufficient
              uint256 thisTrxNum = address(this).balance.sub(trxUnwithdrawnEarnings).sub(joinLabsTrxBalance);
              if(thisTrxNum > 0){
                  for(uint256 i = 1; i <= nodeNowCount; i++) {
                       address nodeAddress = nodeAddressInfo[i];
                       nodeGroupOrders[nodeAddress].trxAllEarnedIncome += thisTrxNum.div(nodeNowCount);
                       trxUnwithdrawnEarnings += thisTrxNum.div(nodeNowCount);
                   }
                   emit WeeklyIncomeStatisticsTrx(msg.sender,thisTrxNum,nodeNowCount,thisTrxNum.div(nodeNowCount),uint256(1));

                   uint256 addTime = countDay.mul(600);
                   trxStatisticsTime += addTime;// Wave field statistics time accumulation
              }
        }

        // Withdrawal TRX
        uint256 trxAllEarnedIncome = nodeGroupOrders[msg.sender].trxAllEarnedIncome;
        require(trxAllEarnedIncome > uint256(0),"-> trxAllEarnedIncome: The revenue of the address withdrawable node is 0.");
        require(address(this).balance > trxAllEarnedIncome,"-> trxAllEarnedIncome: The contract TRX is insufficient.");
        address(uint160(msg.sender)).transfer(trxAllEarnedIncome);// Transfer trx to node address
        nodeGroupOrders[msg.sender].trxAllEarnedIncome = uint256(0);
        nodeGroupOrders[msg.sender].trxFinalExtractTime = block.timestamp;
        trxUnwithdrawnEarnings -= trxAllEarnedIncome;
        nodeGroupOrders[msg.sender].trxExtractionYield += trxAllEarnedIncome;
        emit NodeWithdrawTrx(msg.sender,trxAllEarnedIncome);

        return "nodeWithdrawTrx success";// return result
    }
    // Node withdrawal last week's earnings USDT
    function nodeWithdrawUSDT() public returns (string memory result) {
        // Enable statistics or not
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(usdtStatisticsTime);
        if(diff>600){// The user calls
              uint256 countDay = diff.div(600);
              // Determine whether the contract USDT balance is sufficient
              uint256 thisUsdtNum = usdtTokenContract.balanceOf(address(this)).sub(usdtUnwithdrawnEarnings);
              if(thisUsdtNum > 0){
                   for(uint256 i = 1; i <= nodeNowCount; i++) {
                        address nodeAddress = nodeAddressInfo[i];
                        nodeGroupOrders[nodeAddress].usdtAllEarnedIncome += thisUsdtNum.div(nodeNowCount);
                        usdtUnwithdrawnEarnings += thisUsdtNum.div(nodeNowCount);
                    }
                    emit WeeklyIncomeStatisticsTrx(msg.sender,thisUsdtNum,nodeNowCount,thisUsdtNum.div(nodeNowCount),uint256(1));

                    uint256 addTime = countDay.mul(600);
                    usdtStatisticsTime += addTime;// Wave field statistics time accumulation
              }
        }

        // Withdrawal USDT
        uint256 usdtAllEarnedIncome = nodeGroupOrders[msg.sender].usdtAllEarnedIncome;
        require(usdtAllEarnedIncome > uint256(0),"-> usdtAllEarnedIncome: The revenue of the address withdrawable node is 0.");
        require(usdtTokenContract.balanceOf(address(this)) > usdtAllEarnedIncome,"-> usdtAllEarnedIncome: The contract USDT is insufficient.");
        usdtTokenContract.safeTransfer(msg.sender,usdtAllEarnedIncome);// Transfer usdt to destination address
        nodeGroupOrders[msg.sender].usdtAllEarnedIncome = uint256(0);
        nodeGroupOrders[msg.sender].usdtFinalExtractTime = block.timestamp;
        usdtUnwithdrawnEarnings -= usdtAllEarnedIncome;
        nodeGroupOrders[msg.sender].usdtExtractionYield += usdtAllEarnedIncome;
        emit NodeWithdrawUsdt(msg.sender,usdtAllEarnedIncome);

        return "nodeWithdrawUsdt success";// return result
    }
    // Node withdrawal last week's earnings REA
    function nodeWithdrawREA() public returns (string memory result) {
        // Enable statistics or not
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(reaStatisticsTime);
        if(diff>600){// The user calls
              uint256 countDay = diff.div(600);
              // Determine whether the contract REA balance is sufficient
              uint256 thisReaNum = reaTokenContract.balanceOf(address(this)).sub(reaUnwithdrawnEarnings).sub(preRechargeReaBalance);
              if(thisReaNum > 0){
                  for(uint256 i = 1; i <= nodeNowCount; i++) {
                       address nodeAddress = nodeAddressInfo[i];
                       nodeGroupOrders[nodeAddress].reaAllEarnedIncome += thisReaNum.div(nodeNowCount);
                       reaUnwithdrawnEarnings += thisReaNum.div(nodeNowCount);
                   }
                   emit WeeklyIncomeStatisticsRea(msg.sender,thisReaNum,nodeNowCount,thisReaNum.div(nodeNowCount),uint256(1));

                   uint256 addTime = countDay.mul(600);
                   reaStatisticsTime += addTime;// Wave field statistics time accumulation
              }
        }

        // Withdrawal REA
        uint256 reaAllEarnedIncome = nodeGroupOrders[msg.sender].reaAllEarnedIncome;
        require(reaAllEarnedIncome > uint256(0),"-> reaAllEarnedIncome: The revenue of the address withdrawable node is 0.");
        require(reaTokenContract.balanceOf(address(this)) > reaAllEarnedIncome,"-> reaAllEarnedIncome: The contract USDT is insufficient.");
        reaTokenContract.safeTransfer(msg.sender,reaAllEarnedIncome);// Transfer usdt to destination address
        nodeGroupOrders[msg.sender].reaAllEarnedIncome = uint256(0);
        nodeGroupOrders[msg.sender].reaFinalExtractTime = block.timestamp;
        reaUnwithdrawnEarnings -= reaAllEarnedIncome;
        nodeGroupOrders[msg.sender].reaExtractionYield += reaAllEarnedIncome;
        emit NodeWithdrawUsdt(msg.sender,reaAllEarnedIncome);

        return "nodeWithdrawRea success";// return result
    }
    // Start one cycle settlement REA
   function enableStatisticsOtherCallREA() public returns (string memory result) {
       // Enable statistics or not
       uint256 nowTime = block.timestamp;
       uint256 diff = nowTime.sub(reaStatisticsTime);
       require(diff >= 600,"-> diff: Cycle time has not reached an epoch.");

       // The Other calls
       uint256 countDay = diff.div(600);
       // Determine whether the contract REA balance is sufficient
       uint256 thisReaNum = reaTokenContract.balanceOf(address(this)).sub(reaUnwithdrawnEarnings).sub(preRechargeReaBalance);
       require(thisReaNum > uint256(0),"-> thisReaNum: Insufficient balance of REA available to contract.");

       for(uint256 i = 1; i <= nodeNowCount; i++) {
           address nodeAddress = nodeAddressInfo[i];
           nodeGroupOrders[nodeAddress].reaAllEarnedIncome += thisReaNum.div(nodeNowCount);
           reaUnwithdrawnEarnings += thisReaNum.div(nodeNowCount);
       }
       emit WeeklyIncomeStatisticsRea(msg.sender,thisReaNum,nodeNowCount,thisReaNum.div(nodeNowCount),uint256(2));

       uint256 addTime = countDay.mul(600);
       reaStatisticsTime += addTime;// Wave field statistics time accumulation
       return "enableStatisticsOtherCallREA success";
   }
     // Start one cycle settlement USDT
    function enableStatisticsOtherCallUSDT() public returns (string memory result) {
        // Enable statistics or not
        uint256 nowTime = block.timestamp;
        uint256 diff = nowTime.sub(usdtStatisticsTime);
        require(diff >= 600,"-> diff: Cycle time has not reached an epoch.");

        // The Other calls
        uint256 countDay = diff.div(600);
        // Determine whether the contract USDT balance is sufficient
        uint256 thisUsdtNum = usdtTokenContract.balanceOf(address(this)).sub(usdtUnwithdrawnEarnings);
        require(thisUsdtNum > uint256(0),"-> thisUsdtNum: Insufficient balance of USDT available to contract.");

        for(uint256 i = 1; i <= nodeNowCount; i++) {
            address nodeAddress = nodeAddressInfo[i];
            nodeGroupOrders[nodeAddress].usdtAllEarnedIncome += thisUsdtNum.div(nodeNowCount);
            usdtUnwithdrawnEarnings += thisUsdtNum.div(nodeNowCount);
        }
        emit WeeklyIncomeStatisticsRea(msg.sender,thisUsdtNum,nodeNowCount,thisUsdtNum.div(nodeNowCount),uint256(2));

        uint256 addTime = countDay.mul(600);
        usdtStatisticsTime += addTime;// Wave field statistics time accumulation
        return "enableStatisticsOtherCallUSDT success";
    }
    // Start one cycle settlement TRX
   function enableStatisticsOtherCallTRX() public returns (string memory result) {
       // Enable statistics or not
       uint256 nowTime = block.timestamp;
       uint256 diff = nowTime.sub(trxStatisticsTime);
       require(diff >= 600,"-> diff: Cycle time has not reached an epoch.");

       // The Other calls
       uint256 countDay = diff.div(600);
       // Determine whether the contract TRX balance is sufficient
       uint256 thisTrxNum = address(this).balance.sub(trxUnwithdrawnEarnings).sub(joinLabsTrxBalance);
       require(thisTrxNum > uint256(0),"-> thisTrxNum: Insufficient balance of TRX available to contract.");

       for(uint256 i = 1; i <= nodeNowCount; i++) {
           address nodeAddress = nodeAddressInfo[i];
           nodeGroupOrders[nodeAddress].trxAllEarnedIncome += thisTrxNum.div(nodeNowCount);
           trxUnwithdrawnEarnings += thisTrxNum.div(nodeNowCount);
       }
       emit WeeklyIncomeStatisticsRea(msg.sender,thisTrxNum,nodeNowCount,thisTrxNum.div(nodeNowCount),uint256(2));

       uint256 addTime = countDay.mul(600);
       trxStatisticsTime += addTime;// Wave field statistics time accumulation
       return "enableStatisticsOtherCallTRX success";
   }

}