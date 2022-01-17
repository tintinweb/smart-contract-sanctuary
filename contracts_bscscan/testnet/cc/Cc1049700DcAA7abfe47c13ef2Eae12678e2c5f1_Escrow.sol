// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

import "./IArbitrable.sol";
import "./IArbitrator.sol";
import "./IEvidence.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Escrow is IArbitrable, IEvidence, Ownable {
    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }
    enum RulingOptions {
        RefusedToArbitrate,
        PayerWins,
        PayeeWins
    }

    IERC20 public BUSD;
    uint256 constant numberOfRulingOptions = 2;
    address private _arbitratorAddress;
    address private _marketingWallet;
    address private _rewardsPool;

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error ThirdPartyNotAllowed();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);


    struct TX {
        address payable payer;
        address payable payee;
        IArbitrator arbitrator;
        Status status;
        uint256 value;
        uint256 disputeID;
        uint256 createdAt;
        uint256 reclaimedAt;
        uint256 payerFeeDeposit;
        uint256 payeeFeeDeposit;
        uint256 reclamationPeriod;
        uint256 arbitrationFeeDepositPeriod;
    }


    TX[] public txs;
    mapping(uint256 => uint256) disputeIDtoTXID;

    function setArbitrator(address arbitratorAddress) public onlyOwner {
        _arbitratorAddress = arbitratorAddress;
    }

     function getArbitrator() public view returns (address) {
        return _arbitratorAddress;
    }

    function setMarketingWallet(address marketingWallet) public onlyOwner {
        _marketingWallet = marketingWallet;
    }
  
    function getMarketingWallet() public view returns (address) {
        return _marketingWallet;
    }

    function setRewardsPool(address rewardsPool) public onlyOwner {
        _rewardsPool = rewardsPool;
    }
  
    function getRewardsPool() public view returns (address) {
        return _rewardsPool;
    }

    function payEscrowFee(uint256 _value) public payable returns (uint256){
        if (_value > 253907700313900){ // If msg.value is greater than $333.333 USD in wei
            uint256 marketingWalletAmount = (_value * 15)/1000;
            payable(_marketingWallet).transfer(marketingWalletAmount); //Send 1.5% to marketing wallet
            uint256 rewardsPoolAmount = (_value * 15)/1000;
            payable(_rewardsPool).transfer(rewardsPoolAmount); //Send 1.5% to rewards pool
            _value = _value - marketingWalletAmount - rewardsPoolAmount;
        }

        else{
            uint256 fiveDollarsWei = 1276434351868000;
            payable(_marketingWallet).transfer(fiveDollarsWei); //Send $5 USD in wei to marketing wallet
            payable(_rewardsPool).transfer(fiveDollarsWei); //Send $5 USD in wei to rewards pool
            _value = _value - (fiveDollarsWei * 2);
        }
        return _value;
    }

    function newTransaction(
        address payable _payee,
        uint256 _reclamationPeriod,
        string memory _metaevidence
    ) public payable returns (uint256 txID) { // It may be a good idea to display trasaction ID upon creation
        
        uint256 _value = payEscrowFee(msg.value);
        emit MetaEvidence(txs.length, _metaevidence);
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        BUSD.transferFrom(msg.sender, address(this), _value);

        txs.push(
            TX({
                payer: payable(msg.sender),
                payee: _payee,
                arbitrator: IArbitrator(_arbitratorAddress),
                status: Status.Initial,
                value: _value,
                disputeID: 0,
                createdAt: block.timestamp,
                reclaimedAt: 0,
                payerFeeDeposit: 0,
                payeeFeeDeposit: 0,
                reclamationPeriod: _reclamationPeriod,
                arbitrationFeeDepositPeriod: 72 hours
            })
        );

        txID = txs.length;
    }

    function getTransactions() public view returns (TX[] memory) {
        return txs;
    }

    function releaseFunds(uint256 _txID) public {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) {
            revert InvalidStatus();
        }
        if (
            msg.sender != transaction.payer
        ) {
            revert NotPayer();
        }

        transaction.status = Status.Resolved;
        transaction.payee.transfer(transaction.value);
    }

    function payeeRefundsPayer(uint256 _txID) public {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) {
            revert InvalidStatus();
        }
        if (
            msg.sender != transaction.payee
        ) {
            revert ThirdPartyNotAllowed();
        }
        transaction.status = Status.Resolved;
        transaction.payer.transfer(transaction.value);
    }

    function reclaimFunds(uint256 _txID) public payable { // to initiate a dispute payer will attempt to reclaim funds
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial && transaction.status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        if (msg.sender != transaction.payer) {
            revert NotPayer();
        }
        if (transaction.status == Status.Reclaimed) {
            if (block.timestamp - transaction.reclaimedAt <= transaction.arbitrationFeeDepositPeriod) {
                revert PayeeDepositStillPending();
            }
            transaction.payer.transfer(transaction.value + transaction.payerFeeDeposit);
            transaction.status = Status.Resolved;
        } else {
            if (block.timestamp - transaction.createdAt > transaction.reclamationPeriod) {
                revert ReclaimedTooLate();
            }

            transaction.payerFeeDeposit = msg.value;
            transaction.reclaimedAt = block.timestamp;
            transaction.status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee(uint256 _txID) public payable {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        transaction.payeeFeeDeposit = msg.value;
        transaction.disputeID = transaction.arbitrator.createDispute{value: msg.value}(numberOfRulingOptions, msg.value);
        transaction.status = Status.Disputed;
        disputeIDtoTXID[transaction.disputeID] = _txID;
        emit Dispute(transaction.arbitrator, transaction.disputeID, _txID, _txID);
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        uint256 txID = disputeIDtoTXID[_disputeID];
        TX storage transaction = txs[txID];

        if (msg.sender != address(transaction.arbitrator)) {
            revert NotArbitrator();
        }
        if (transaction.status != Status.Disputed) {
            revert InvalidStatus();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }
        transaction.status = Status.Resolved;

        if (_ruling == uint256(RulingOptions.PayerWins)){
            transaction.payer.transfer(transaction.value + transaction.payerFeeDeposit);
            payable(address(transaction.arbitrator)).transfer(transaction.payeeFeeDeposit);
            }
        if (_ruling == uint256(RulingOptions.PayeeWins)){
            transaction.payee.transfer(transaction.value + transaction.payeeFeeDeposit);
            payable(address(transaction.arbitrator)).transfer(transaction.payerFeeDeposit);
            }
        if (_ruling == uint256(RulingOptions.RefusedToArbitrate)){ // If arbitrator refuses to arbitrate return arbitration fees to payer and payee
            transaction.payee.transfer(transaction.payeeFeeDeposit);
            transaction.payer.transfer(transaction.payerFeeDeposit);
            transaction.payeeFeeDeposit = 0;
            transaction.payerFeeDeposit = 0;
            transaction.status = Status.Initial; // Revert to initial status
            transaction.createdAt = block.timestamp; // Update created at to now
            transaction.reclamationPeriod = 2 weeks; // Set transaction reclamation period to 2 weeks to allow parties to resolve their issues
            }
        emit Ruling(transaction.arbitrator, _disputeID, _ruling);
    }

    function submitEvidence(uint256 _txID, string memory _evidence) public {
        TX storage transaction = txs[_txID];

        if (transaction.status == Status.Resolved) {
            revert InvalidStatus();
        }

        if (msg.sender != transaction.payer && msg.sender != transaction.payee) {
            revert ThirdPartyNotAllowed();
        }
        emit Evidence(transaction.arbitrator, _txID, msg.sender, _evidence);
    }

    function remainingTimeToReclaim(uint256 _txID) public view returns (uint256) {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Initial) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - transaction.createdAt) > transaction.reclamationPeriod
                ? 0
                : (transaction.createdAt + transaction.reclamationPeriod - block.timestamp);
    }

    function remainingTimeToDepositArbitrationFee(uint256 _txID) public view returns (uint256) {
        TX storage transaction = txs[_txID];

        if (transaction.status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - transaction.reclaimedAt) > transaction.arbitrationFeeDepositPeriod
                ? 0
                : (transaction.reclaimedAt + transaction.arbitrationFeeDepositPeriod - block.timestamp);
    }
}