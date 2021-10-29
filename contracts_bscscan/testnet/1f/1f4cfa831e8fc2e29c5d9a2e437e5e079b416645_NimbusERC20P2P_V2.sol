/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity =0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    function safeTransferBNB(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface INBU_WBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
interface IBEP20Permit {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract NimbusERC20P2P_V2 is IERC721Receiver {    
    struct Trade {
        address initiator;
        address counterparty;
        address proposedAsset;
        uint proposedAmount;
        address askedAsset;
        uint askedAmount;
        uint deadline;
        uint status; //0: Active, 1: success, 2: canceled, 3: withdrawn
        uint tradeType; //0: ERC20, 1: ERC20toERC721, 2:ERC721toErc20, 3: NFTtoETH
    }

    struct TradeNFT {
        address initiator;
        address counterparty;
        address[] proposedAsset;
        uint[] proposedTokenId;
        address[] askedAsset;
        uint[] askedTokenId;
        uint deadline;
        uint status; //0: Active, 1: success, 2: canceled, 3: withdrawn
        uint tradeType; //0: ERC20toERC20, 1: ERC20toERC721, 2:ERC721toErc20, 3: ERC721toERC721
    }

    enum TradeState {
        Active,
        Succeeded,
        Canceled,
        Withdrawn,
        Overdue
    }

    INBU_WBNB public immutable NBU_WBNB;
    uint public tradeCount;
    uint public tradeCountNFT;
    mapping(uint => Trade) public trades;
    mapping(uint => TradeNFT) tradesNFT;
    mapping(address => uint[]) private _userTrades;
    mapping(address => uint[]) private _userTradesNFT;

    event NewTrade(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint tradeId);
    event NewTradeNFT(address[] proposedAsset, uint[] proposedAmount, address[] askedAsset, uint[] askedAmount, uint deadline, uint tradeId);
    event SupportTrade(uint tradeId, address counterparty);
    event CancelTrade(uint tradeId);
    event WithdrawOverdueAsset(uint tradeId);
    
    constructor(address nbuWbnb) {
        require(Address.isContract(nbuWbnb), "NimbusBEP20P2P_V1: Not contract");
        NBU_WBNB = INBU_WBNB(nbuWbnb);
    }
    receive() external payable {
        assert(msg.sender == address(NBU_WBNB)); // only accept BNB via fallback from the NBU_WBNB contract
    }
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'NimbusERC20P2P_V1: locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        return 0x150b7a02;
    }    
    function getNFTtrades(uint id) external view returns(TradeNFT memory) {
         return tradesNFT[id];
     }
    function createTrade(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contracts");
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline, 0);   
    }    
    function createTradeERC20toNFT(address proposedAsset, uint proposedAmount, address askedAsset, uint tokenId, uint deadline) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset), "NimbusERC20P2P_V1: Not contracts");
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, tokenId, deadline, 1);   
    }   
    function createTradeNFTtoERC20(address proposedAsset, uint tokenId, address askedAsset, uint askedAmount, uint deadline) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset), "NimbusERC20P2P_V1: Not contracts");
        IERC721(proposedAsset).safeTransferFrom(msg.sender, address(this), tokenId);
        tradeId = _createTrade(proposedAsset, tokenId, askedAsset, askedAmount, deadline, 2);   
    }
    function createTradeNFTtoNFT(address[] calldata proposedAsset, uint[] calldata proposedTokenId, address[] calldata askedAsset, uint[] calldata askedTokenId, uint deadline) external returns (uint tradeId) {
        for(uint i=0; i < askedAsset.length; i++) {
          require(Address.isContract(askedAsset[i]), "NimbusERC20P2P_V1: Not contracts");
        }
        for(uint i=0; i < proposedAsset.length; i++) {
          require(Address.isContract(proposedAsset[i]), "NimbusERC20P2P_V1: Not contracts");
          IERC721(proposedAsset[i]).safeTransferFrom(msg.sender, address(this), proposedTokenId[i]);
        }        
        tradeId = _createTradeNFTtoNFT(proposedAsset, proposedTokenId, askedAsset, askedTokenId, deadline, 3);   
    }
    function createTradeBNB(address askedAsset, uint askedAmount, uint deadline) payable external returns (uint tradeId) {
        require(Address.isContract(askedAsset), "NimbusBEP20P2P_V1: Not contract");
        NBU_WBNB.deposit{value: msg.value}();
        tradeId = _createTrade(address(NBU_WBNB), msg.value, askedAsset, askedAmount, deadline,0);   
    }
    function createTradeBNBtoNFT(address askedAsset, uint askedAmount, uint deadline) payable external returns (uint tradeId) {
        require(Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contract");
        NBU_WBNB.deposit{value: msg.value}();
        tradeId = _createTrade(address(NBU_WBNB), msg.value, askedAsset, askedAmount, deadline, 0);   
    }
    function createTradeNFTtoBNB(address proposedAsset, uint tokenId, uint askedAmount, uint deadline) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset), "NimbusERC20P2P_V1: Not contracts");
        IERC721(proposedAsset).safeTransferFrom(msg.sender, address(this), tokenId);
        tradeId = _createTrade(proposedAsset, tokenId, address(NBU_WBNB), askedAmount, deadline, 3);   
    }   
    function createTradeWithPermit(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contracts");
        IBEP20Permit(proposedAsset).permit(msg.sender, address(this), proposedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline, 0);   
    }
    function createTradeWithPermitERC20toNFT(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contracts");
        IBEP20Permit(proposedAsset).permit(msg.sender, address(this), proposedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(proposedAsset, msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline, 0);   
    }
    function createTradeWithPermitNFTtoERC20(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external returns (uint tradeId) {
        require(Address.isContract(proposedAsset) && Address.isContract(askedAsset), "NimbusERC20P2P_V1: Not contracts");
        IERC721(proposedAsset).safeTransferFrom(msg.sender, address(this), proposedAmount);
        tradeId = _createTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline, 2);   
    }
    function supportTrade(uint tradeId) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }    
    function supportTradeERC20toNFT(uint tradeId) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        IERC721(trade.askedAsset).safeTransferFrom(msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeNFTtoNFT(uint tradeId) external lock {
        require(tradeCountNFT >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        TradeNFT storage tradeNFT = tradesNFT[tradeId];
        require(tradeNFT.status == 0 && tradeNFT.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        for(uint i=0; i < tradeNFT.askedAsset.length; i++) {
          IERC721(tradeNFT.askedAsset[i]).safeTransferFrom(msg.sender, tradeNFT.initiator, tradeNFT.askedTokenId[i]);
        }
        _supportTradeNFTtoNFT(tradeId);
    }   
    function supportTradeNFTtoERC20(uint tradeId) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeBNB(uint tradeId) payable external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        require(msg.value >= trade.askedAmount, "NimbusERC20P2P_V1: Not enough ETH sent");
        require(trade.askedAsset == address(NBU_WBNB), "NimbusERC20P2P_V1: ERC20 trade");
        TransferHelper.safeTransferBNB(trade.initiator, trade.askedAmount);
        if (msg.value > trade.askedAmount) TransferHelper.safeTransferBNB(msg.sender, msg.value - trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeBNBtoNFT(uint tradeId) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        IERC721(trade.askedAsset).safeTransferFrom(msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeNFTtoBNB(uint tradeId) payable external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        require(msg.value >= trade.askedAmount, "NimbusERC20P2P_V1: Not enough BNB sent");
        TransferHelper.safeTransferBNB(trade.initiator, trade.askedAmount);
        if (msg.value > trade.askedAmount) TransferHelper.safeTransferBNB(msg.sender, msg.value - trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeWithPermit(uint tradeId, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        IBEP20Permit(trade.askedAsset).permit(msg.sender, address(this), trade.askedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeWithPermitERC20toNFT(uint tradeId) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        IERC721(trade.askedAsset).safeTransferFrom(msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }
    function supportTradeWithPermitNFTtoERC20(uint tradeId, uint permitDeadline, uint8 v, bytes32 r, bytes32 s) external lock {
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        IBEP20Permit(trade.askedAsset).permit(msg.sender, address(this), trade.askedAmount, permitDeadline, v, r, s);
        TransferHelper.safeTransferFrom(trade.askedAsset, msg.sender, trade.initiator, trade.askedAmount);
        _supportTrade(tradeId);
    }
    function cancelTrade(uint tradeId) external lock { 
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "NimbusERC20P2P_V1: not allowed");
        require(trade.status == 0 && trade.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        trade.status = 2;
        if (trade.proposedAsset != address(NBU_WBNB) && trade.tradeType != 2 && trade.tradeType != 3) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else if (trade.tradeType == 2) {
          IERC721(trade.proposedAsset).transferFrom(address(this), msg.sender, trade.proposedAmount);
        } else if (trade.tradeType == 3) {
          IERC721(trade.proposedAsset).transferFrom(address(this), msg.sender, trade.proposedAmount);
        } else {
            NBU_WBNB.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferBNB(msg.sender, trade.proposedAmount);
        }
        emit CancelTrade(tradeId);
    }

    function cancelTradeNFT(uint tradeId) external lock { 
        require(tradeCountNFT >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        TradeNFT storage tradeNFT = tradesNFT[tradeId];
        require(tradeNFT.initiator == msg.sender, "NimbusERC20P2P_V1: not allowed");
        require(tradeNFT.status == 0 && tradeNFT.deadline > block.timestamp, "NimbusERC20P2P_V1: not active trade");
        tradeNFT.status = 2;
        for(uint i=0; i < tradeNFT.proposedAsset.length; i++) {           
          IERC721(tradeNFT.proposedAsset[i]).transferFrom(address(this), msg.sender, tradeNFT.proposedTokenId[i]);
        } 
        emit CancelTrade(tradeId);
    }
    function withdrawOverdueAsset(uint tradeId) external lock { 
        require(tradeCount >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        Trade storage trade = trades[tradeId];
        require(trade.initiator == msg.sender, "NimbusERC20P2P_V1: not allowed");
        require(trade.status == 0 && trade.deadline < block.timestamp, "NimbusERC20P2P_V1: not available for withdrawal");
        if (trade.proposedAsset != address(NBU_WBNB) && trade.tradeType != 2 && trade.tradeType != 3) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else if (trade.tradeType == 2) {
          IERC721(trade.proposedAsset).transferFrom(address(this), msg.sender, trade.proposedAmount);
        } else if (trade.tradeType == 3) {
          IERC721(trade.proposedAsset).transferFrom(address(this), msg.sender, trade.proposedAmount);
        } else {
            NBU_WBNB.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferBNB(msg.sender, trade.proposedAmount);
        }
        trade.status = 3;
        emit WithdrawOverdueAsset(tradeId);
    }
    function withdrawOverdueAssetNFT(uint tradeId) external lock { 
        require(tradeCountNFT >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        TradeNFT storage tradeNFT = tradesNFT[tradeId];
        require(tradeNFT.initiator == msg.sender, "NimbusERC20P2P_V1: not allowed");
        require(tradeNFT.status == 0 && tradeNFT.deadline < block.timestamp, "NimbusERC20P2P_V1: not available for withdrawal");
        for(uint i=0; i < tradeNFT.proposedAsset.length; i++) {           
          IERC721(tradeNFT.proposedAsset[i]).transferFrom(address(this), msg.sender, tradeNFT.proposedTokenId[i]);
        } 
        tradeNFT.status = 3;
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
    function stateNFT(uint tradeId) public view returns (TradeState) {
        require(tradeCountNFT >= tradeId && tradeId > 0, "NimbusERC20P2P_V1: invalid trade id");
        TradeNFT storage tradeNFT = tradesNFT[tradeId];
        if (tradeNFT.status == 1) {
            return TradeState.Succeeded;
        } else if (tradeNFT.status == 2 || tradeNFT.status == 3) {
            return TradeState(tradeNFT.status);
        } else if (tradeNFT.deadline < block.timestamp) {
            return TradeState.Overdue;
        } else {
            return TradeState.Active;
        }
    }
    function userTrades(address user) public view returns (uint[] memory) {
        return _userTrades[user];
    }
    function userTradesNFT(address user) public view returns (uint[] memory) {
        return _userTradesNFT[user];
    }
    function _createTrade(address proposedAsset, uint proposedAmount, address askedAsset, uint askedAmount, uint deadline, uint tradeType) private returns (uint tradeId) { 
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
        trade.tradeType = tradeType; 
        _userTrades[msg.sender].push(tradeId);        
        emit NewTrade(proposedAsset, proposedAmount, askedAsset, askedAmount, deadline, tradeId);
    }
    function _createTradeNFTtoNFT(address[] calldata proposedAsset, uint[] calldata proposedTokenId, address[] calldata askedAsset, uint[] calldata askedTokenId, uint deadline, uint tradeType) private returns (uint tradeId) { 
        require(proposedTokenId.length > 0, "NimbusERC20P2P_V1: zero proposed tokens");
        require(askedTokenId.length > 0, "NimbusERC20P2P_V1: zero asked tokens");
        require(proposedAsset.length > 0, "NimbusERC20P2P_V1: zero propossed asset");
        require(askedAsset.length > 0, "NimbusERC20P2P_V1: zero asked asset");
        require(deadline > block.timestamp, "NimbusERC20P2P_V1: incorrect deadline");
        tradeId = ++tradeCountNFT;
        TradeNFT storage tradeNFT = tradesNFT[tradeId];
        tradeNFT.initiator = msg.sender;
        tradeNFT.proposedAsset = proposedAsset;
        tradeNFT.proposedTokenId = proposedTokenId;
        tradeNFT.askedAsset = askedAsset;
        tradeNFT.askedTokenId = askedTokenId;
        tradeNFT.deadline = deadline;
        tradeNFT.tradeType = tradeType;
        tradesNFT[tradeId] = tradeNFT;
        _userTradesNFT[msg.sender].push(tradeId);      
        emit NewTradeNFT(proposedAsset, proposedTokenId, askedAsset, askedTokenId, deadline, tradeId);
    }
    function _supportTrade(uint tradeId) private { 
        Trade storage trade = trades[tradeId];
        if (trade.proposedAsset != address(NBU_WBNB) && trade.tradeType != 2 && trade.tradeType != 3) {
            TransferHelper.safeTransfer(trade.proposedAsset, msg.sender, trade.proposedAmount);
        } else if (trade.tradeType == 2) {
          IERC721(trade.proposedAsset).transferFrom(address(this), msg.sender, trade.proposedAmount);
        } else if (trade.tradeType == 3) {
          IERC721(trade.proposedAsset).transferFrom(address(this), msg.sender, trade.proposedAmount);
        } else {
            NBU_WBNB.withdraw(trade.proposedAmount);
            TransferHelper.safeTransferBNB(msg.sender, trade.proposedAmount);
        }
        trade.counterparty = msg.sender;
        trade.status = 1;
        emit SupportTrade(tradeId, msg.sender);
    }
    function _supportTradeNFTtoNFT(uint tradeId) private { 
        TradeNFT storage tradeNFT = tradesNFT[tradeId];
        for(uint i=0; i < tradeNFT.proposedAsset.length; i++) {           
          IERC721(tradeNFT.proposedAsset[i]).transferFrom(address(this), msg.sender, tradeNFT.proposedTokenId[i]);
        } 
        tradeNFT.counterparty = msg.sender;
        tradeNFT.status = 1;
        emit SupportTrade(tradeId, msg.sender);
    }
 }