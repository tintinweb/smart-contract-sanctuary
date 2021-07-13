/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

pragma solidity =0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface INBU_WETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract NimbusERC20P2P_V1 {    
    struct Trade {
        address initiator;
        address counterparty;
        address proposedAsset;
        uint proposedAmount;
        address askedAsset;
        uint askedAmount;
        uint deadline;
        uint status; //0: Active, 1: success, 2: canceled, 3: withdrawn
    }

    enum TradeState {
        Active,
        Succeeded,
        Canceled,
        Withdrawn,
        Overdue
    }

    INBU_WETH public immutable NBU_WETH;

    uint public tradeCount;
    mapping(uint => Trade) public trades;
    mapping(address => uint[]) private _userTrades;

    event NewTrade(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint tradeId);
    event SupportTrade(uint tradeId, address counterparty);
    event CancelTrade(uint tradeId);
    event WithdrawOverdueAsset(uint tradeId);
    
    constructor(address nbuWeth) {
        require(Address.isContract(nbuWeth), "NimbusERC20P2P_V1: Not contract");
        NBU_WETH = INBU_WETH(nbuWeth);
    }

    receive() external payable {
        assert(msg.sender == address(NBU_WETH)); // only accept ETH via fallback from the NBU_WETH contract
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'NimbusERC20P2P_V1: locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function createTrade(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contracts");
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline);   
    }

    function createTradeETH(address askedAsset, uint askedAmount, uint deadline) payable external returns (uint tradeId) {
        require(Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contract");
        NBU_WETH.deposit{value: msg.value}();
        tradeId = _createTrade(address(NBU_WETH), msg.value, askedAsset, askedAmount, deadline);   
    }

    function createTradeWithPermit(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contracts");
        IERC20Permit(proposedAsset).permit(msg.sender, address(this), proposedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline);   
    }


    function supportTrade(uint tradeId) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");

        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }

    function supportTradeETH(uint tradeId) payable external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        require(msg.value >= trade.askedAmount, "NimbusERC20P2P_V1: Not enough ETH sent");
        require(trade.askedAsset == address(NBU_WETH), "NimbusERC20P2P_V1: ERC20 trade");

        TransferHelper.safeTransferETH(trade.initiator, trade.askedAmount);
        if (msg.value > trade.askedAmount) TransferHelper.safeTransferETH(msg.sender, msg.value - trade.askedAmount);
        _supportTrade(tradeId);
    }

    function supportTradeWithPermit(uint tradeId, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");

        IERC20Permit(trade.askedAsset).permit(msg.sender, address(this), trade.askedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }

    function cancelTrade(uint tradeId) external lock { 
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "NimbusERC20P2P_V1: not allowed");
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        trade.status = 2;

        if (trade.proposedAsset != address(NBU_WETH)) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else {
            NBU_WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferETH(msg.sender, trade.proposedAmount);
        }

        emit CancelTrade(tradeId);
    }

    function withdrawOverdueAsset(uint tradeId) external lock { 
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "NimbusERC20P2P_V1: not allowed");
        require(trade.status == 0 && trade.deadline < block.timestamp, "NimbusERC20P2P_V1: not available for withdrawal");

        if (trade.proposedAsset != address(NBU_WETH)) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else {
            NBU_WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferETH(msg.sender, trade.proposedAmount);
        }

        trade.status = 3;

        emit WithdrawOverdueAsset(tradeId);
    }

    function state(uint tradeId) public view returns (TradeState) {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        if (trade.status == 1) {
            return TradeState.Succeeded;
        } else if (trade.status == 2 || trade.status == 3) {
            return TradeState(trade.status);
        } else if (trade.deadline < block.timestamp) {
            return TradeState.Overdue;
        } else {
            return TradeState.Active;
        }
    }

    function userTrades(address user) public view returns (uint[] memory) {
        return _userTrades[user];
    }



    function _createTrade(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline) private returns (uint tradeId) { 
        require(askedAsset != proposedAsset, "NimbusERC20P2P_V1: asked asset can't be equal to proposed asset");
        require(proposedAmount > 0, "NimbusERC20P2P_V1: zero proposed amount");
        require(askedAmount > 0, "NimbusERC20P2P_V1: zero asked amount");
        require(deadline > block.timestamp, "NimbusERC20P2P_V1: incorrect deadline");
        tradeId = ++tradeCount;
        Trade storage trade = trades[tradeId];
        trade.initiator = msg.sender;
        trade.proposedAsset = proposedAsset;
        trade.proposedAmount = proposedAmount;
        trade.askedAsset = askedAsset;
        trade.askedAmount = askedAmount;
        trade.deadline = deadline;
        
        _userTrades[msg.sender].push(tradeId);
        
        emit NewTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline, tradeId);
    }

    function _supportTrade(uint tradeId) private { 
        Trade storage trade = trades[tradeId];

        if (trade.proposedAsset != address(NBU_WETH)) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else {
            NBU_WETH.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferETH(msg.sender, trade.proposedAmount);
        }
        trade.counterparty = msg.sender;
        trade.status = 1;
        emit SupportTrade(tradeId, msg.sender);
    }
 }