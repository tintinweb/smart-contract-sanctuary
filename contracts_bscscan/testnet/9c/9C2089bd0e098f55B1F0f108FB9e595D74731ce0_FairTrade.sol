// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

import "./IOwnable.sol";


/*
Alice and Bob want to trade ownable items

Alice initiate a trade and put some addresses in a A list [aItem1Address, aItem2Address, aItem3Address]
Alice transfers ownership of all items to this contract
Alice click on confirm trade

Bob join the trade and put some addresses in a B list [bItem1Address, bItem2Address]
Bob transfers ownership of all items to this contract
Bob click on confirm trade

When anyone clicks on execute trade button -> ownerships are swapped

========

While both participants have not confirm the trade, any participant can cancel the trade

*/

contract FairTrade {
    uint256 _seed = 0;

    mapping(bytes32 => Trade) _trades;

    struct Trade {
        address a;
        address[] aItems;
        uint256 aEthBalance;
        bool hasAConfirmed;
        address b;
        address[] bItems;
        uint256 bEthBalance;
        bool hasBConfirmed;
        TradeStatus status;
    }

    enum TradeStatus{PENDING, CONFIRMED, DONE, CANCELED}

    event InitTrade(
        bytes32 tradeId,
        address a
    );

    event JoinTrade(
        bytes32 tradeId,
        address b
    );

    event ConfirmTrade(
        bytes32 tradeId,
        address participant
    );

    event CancelTrade(
        bytes32 tradeId,
        address participant
    );

    event TransferBackOwnership(
        bytes32 tradeId,
        address item,
        address owner
    );

    event TransferOwnership(
        bytes32 tradeId,
        address item,
        address from,
        address to
    );

    event TransferOwnershipToContract(
        bytes32 tradeId,
        address item,
        address from
    );

    event TransferEth(
        bytes32 tradeId,
        uint256 amount,
        address from,
        address to
    );

    event TransferEthToContract(
        bytes32 tradeId,
        uint256 amount,
        address from
    );

    event TransferBackEth(
        bytes32 tradeId,
        uint256 amount,
        address recipient
    );

    event DoneTrade(
        bytes32 tradeId,
        address participant
    );

    receive() external payable {
    }

    function initTrade(address[] calldata items) public payable returns (bytes32){
        require(items.length > 0 || msg.value > 0, "Must provide something to trade");
        bytes32 tradeId = getUniqueIdentifier(msg.sender);

        address[] memory _bItems;

        Trade memory trade = Trade({
        a : msg.sender,
        aItems : items,
        aEthBalance : msg.value,
        hasAConfirmed : false,
        b : address(0),
        bItems : _bItems,
        bEthBalance : 0,
        hasBConfirmed : false,
        status : TradeStatus.PENDING
        });

        _trades[tradeId] = trade;

        if (msg.value > 0) {
            emit TransferEthToContract(tradeId, msg.value, msg.sender);
        }
        emit InitTrade(tradeId, msg.sender);

        return tradeId;
    }

    function initTrade(address[] calldata items, address b) public payable returns (bytes32){
        require(items.length > 0 || msg.value > 0, "Must provide something to trade");
        bytes32 tradeId = getUniqueIdentifier(msg.sender);

        address[] memory _bItems;

        Trade memory trade = Trade({
        a : msg.sender,
        aItems : items,
        aEthBalance : msg.value,
        hasAConfirmed : false,
        b : b,
        bItems : _bItems,
        bEthBalance : 0,
        hasBConfirmed : false,
        status : TradeStatus.PENDING
        });

        _trades[tradeId] = trade;

        if (msg.value > 0) {
            emit TransferEthToContract(tradeId, msg.value, msg.sender);
        }
        emit InitTrade(tradeId, msg.sender);

        return tradeId;
    }

    function seekTrade(bytes32 tradeId) external view returns (
        address a,
        address[] memory aItems,
        uint256 aEthBalance,
        bool hasAConfirmed,
        address b,
        address [] memory bItems,
        uint256 bEthBalance,
        bool hasBConfirmed){

        Trade memory trade = _trades[tradeId];

        return (
        trade.a,
        trade.aItems,
        trade.aEthBalance,
        trade.hasAConfirmed,
        trade.b,
        trade.bItems,
        trade.bEthBalance,
        trade.hasBConfirmed
        );
    }

    function joinTrade(bytes32 tradeId, address[] calldata items) public payable {
        Trade memory trade = _trades[tradeId];
        require(trade.a != address(0), "Bad tradeId");
        require(trade.a != msg.sender, "Cannot trade with yourself");
        require(items.length > 0 || msg.value > 0, "Must provide something to trade");
        if (trade.b != address(0)) {
            require(msg.sender == trade.b, "This trade already has a second participant");
        }

        trade.b = msg.sender;
        trade.bItems = items;
        trade.bEthBalance = msg.value;

        if (msg.value > 0) {
            emit TransferEthToContract(tradeId, msg.value, msg.sender);
        }
        emit JoinTrade(tradeId, msg.sender);

        _trades[tradeId] = trade;
    }

    //TODO: an improvment could be: no need to click on execute, as soon as the second part confirm, the trade is executed
    function confirmTrade(bytes32 tradeId) public {
        Trade memory trade = _trades[tradeId];
        checkTradeParticipant(trade, msg.sender);
        //check that all ownerShip have been transferred to this contract
        if (trade.a == msg.sender) {
            for (uint i = 0; i < trade.aItems.length; i++) {
                require(IOwnable(trade.aItems[i]).owner() == address(this), "An item ownership has not been transferred");
            }
            trade.hasAConfirmed = true;
            emit ConfirmTrade(tradeId, msg.sender);
        } else {
            for (uint i = 0; i < trade.bItems.length; i++) {
                require(IOwnable(trade.bItems[i]).owner() == address(this), "An item ownership has not been transferred");
            }
            trade.hasBConfirmed = true;
            emit ConfirmTrade(tradeId, msg.sender);
        }
        if (trade.hasAConfirmed && trade.hasBConfirmed) {
            trade.status = TradeStatus.CONFIRMED;
        }
        _trades[tradeId] = trade;
    }

    function checkTradeParticipant(Trade memory trade, address participantAddress) pure internal {
        require(trade.a == participantAddress || trade.b == participantAddress, "Participant not in this trade");
    }

    function cancelTrade(bytes32 tradeId) public {
        Trade memory trade = _trades[tradeId];
        checkTradeParticipant(trade, msg.sender);
        require(!(trade.hasAConfirmed && trade.hasBConfirmed), "Trade already confirmed");

        for (uint i = 0; i < trade.aItems.length; i++) {
            if (IOwnable(trade.aItems[i]).owner() == address(this)) {
                IOwnable(trade.aItems[i]).transferOwnership(trade.a);
                emit TransferBackOwnership(tradeId, trade.aItems[i], trade.a);
            }
        }

        if (trade.aEthBalance > 0) {
            payable(trade.a).transfer(trade.aEthBalance);
            emit TransferBackEth(tradeId, trade.aEthBalance, trade.a);
        }

        for (uint i = 0; i < trade.bItems.length; i++) {
            if (IOwnable(trade.bItems[i]).owner() == address(this)) {
                IOwnable(trade.bItems[i]).transferOwnership(trade.b);
                emit TransferBackOwnership(tradeId, trade.bItems[i], trade.b);
            }
        }

        if (trade.bEthBalance > 0) {
            payable(trade.b).transfer(trade.bEthBalance);
            emit TransferBackEth(tradeId, trade.bEthBalance, trade.b);
        }

        trade.status = TradeStatus.CANCELED;

        emit CancelTrade(tradeId, msg.sender);

        _trades[tradeId] = trade;
    }

    function executeTrade(bytes32 tradeId) public {
        Trade memory trade = _trades[tradeId];
        require(TradeStatus.CONFIRMED == trade.status, "Trade status is not confirmed");

        for (uint i = 0; i < trade.aItems.length; i++) {
            IOwnable(trade.aItems[i]).transferOwnership(trade.b);
            emit TransferOwnership(tradeId, trade.aItems[i], trade.a, trade.b);
        }

        if (trade.aEthBalance > 0) {
            payable(trade.b).transfer(trade.aEthBalance);
            emit TransferEth(tradeId, trade.aEthBalance, trade.a, trade.b);
        }

        for (uint i = 0; i < trade.bItems.length; i++) {
            IOwnable(trade.bItems[i]).transferOwnership(trade.a);
            emit TransferOwnership(tradeId, trade.bItems[i], trade.b, trade.a);
        }

        if (trade.bEthBalance > 0) {
            payable(trade.a).transfer(trade.bEthBalance);
            emit TransferEth(tradeId, trade.bEthBalance, trade.b, trade.a);
        }

        trade.status = TradeStatus.DONE;

        emit DoneTrade(tradeId, msg.sender);

        _trades[tradeId] = trade;

    }

    function getUniqueIdentifier(address a) internal returns (bytes32){
        _seed++;
        return keccak256(abi.encodePacked(_seed + block.timestamp, a));
    }

    function seekOwner(address item) external view returns (address) {
        return IOwnable(item).owner();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0;

interface IOwnable{
    function owner() external view returns (address);
    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
}