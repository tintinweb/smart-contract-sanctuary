// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "AggregatorV3Interface.sol";

contract RoyaltyManagementMulti {
    //using SafeMathChainlink for uint256; useless with new solidity version

    mapping(address => uint256) private artistsBalance;
    address private owner;
    AggregatorV3Interface private priceFeed;

    //A dynamic uint called _transactionIdx that increments
    uint256 private _transactionIdx;
    //A dynamic uint called _workIdx that increments
    uint256 private _workIdx;

    //create a struct to represent a transaction that is submitted for others to approve.
    //we need to keep track of who signed (which accounts) the transition
    struct Transaction {
        uint256 work_id;
        address from;
        address to;
        uint256 amount;
        uint8 shares;
        bool sellerSignature;
        bool buyerSignature;
    }

    struct Work {
        uint256 id;
        string CID;
        address[] artists;
    }

    mapping(uint256 => Work) private idToWork;
    mapping(uint256 => mapping(address => uint8)) public addressToShares;
    mapping(uint256 => mapping(address => uint8)) public addressToSharesOnSale;

    //This is a mapping of transaction ID to a transaction.
    mapping(uint256 => Transaction) private _transactions;

    //create a dynamic array called _pendingTransactions
    //this will contain the list of pending transactions that need to be processed
    uint256[] private _pendingTransactions;

    event DepositFunds(address from, uint256 amount);
    event WithdrawFunds(address from, uint256 amount);
    event TransferFunds(address from, address to, uint256 amount);
    event TransactionCreated(
        address from,
        address to,
        uint256 amount,
        uint8 shares,
        uint256 transactionId
    );
    event TransactionSigned(address by, uint256 transactionId);

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    /***************
    MODIFIERS
    ***************/

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You have to be the owner of the contract!"
        );
        _;
    }

    modifier onlyValidBalance() {
        require(artistsBalance[msg.sender] >= 0, "Your balance is 0");
        _;
    }

    /***************
    TRANSACTIONS
    ***************/

    function createWork(string memory cid) public {
        //each Work needs a workId
        //system will create a workId by adding a number to the last id created (hence the use of ++)
        uint256 workId = _workIdx++;

        //create a work using the struct and put in memory
        //then add the information to the work in memory
        Work memory work;
        work.CID = cid;
        work.artists[work.artists.length] = msg.sender;

        //add the work to the idToWork data structure (work map)
        //work ID to the actual work
        //Add this work to the dynamic array using the push mechanism using the transactionId
        idToWork[workId] = work;

        addressToShares[workId][msg.sender] = 100;
    }

    function fund(uint256 work_id) public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        Work storage work = idToWork[work_id];

        for (
            uint8 artistIntex = 0;
            artistIntex < work.artists.length;
            artistIntex++
        ) {
            address artist = work.artists[artistIntex];
            artistsBalance[artist] = uint256(
                (msg.value * addressToShares[work_id][artist]) / 100
            );
        }

        emit DepositFunds(msg.sender, msg.value);
    }

    function transferTo(
        address to,
        uint256 amount,
        uint8 shares,
        uint256 work_id
    ) public {
        Work storage work = idToWork[work_id];
        require(
            addressToShares[work_id][msg.sender] -
                addressToSharesOnSale[work_id][msg.sender] >=
                shares
        );

        //each Transaction needs a transactionId
        //system will create a transactionId by adding a number to the last id created (hence the use of ++)
        uint256 transactionId = _transactionIdx++;

        //create a transaction using the struct and put in memory
        //then add the information to the Transaction in memory
        Transaction memory transaction;
        transaction.work_id = work_id;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.shares = shares;
        addressToSharesOnSale[work_id][msg.sender] += shares;
        transaction.sellerSignature = true;

        //add the transaction to the _transactions data structure (transaction map)
        //Transaction ID to the actual transaction
        //Add this transaction to the dynamic array using the push mechanism using the transactionId
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);

        //create an event that the transaction was created
        emit TransactionCreated(msg.sender, to, amount, shares, transactionId);
        emit TransactionSigned(msg.sender, transactionId);
    }

    function signTransaction(uint256 transactionId) public payable {
        //go to _transactions and get the transactionId and give it the variable name transaction
        Transaction storage transaction = _transactions[transactionId];

        Work storage work = idToWork[transaction.work_id];

        //Transaction must exist
        require(address(0x0) != transaction.from);
        //creator cannot sign the transaction
        require(msg.sender != transaction.from);

        if (address(0x0) == transaction.to) {
            transaction.to = msg.sender;
        }

        require(msg.sender == transaction.to);

        //sign the tranaction
        transaction.buyerSignature = true;
        //emit an event
        emit TransactionSigned(msg.sender, transactionId);

        if (
            transaction.buyerSignature == true &&
            transaction.sellerSignature == true
        ) {
            //check balance
            require(msg.value >= transaction.amount);
            payable(transaction.from).transfer(msg.value);

            addressToSharesOnSale[work.id][transaction.from] -= transaction
                .shares;
            addressToShares[work.id][transaction.from] -= transaction.shares;
            addressToShares[work.id][transaction.to] += transaction.shares;
            work.artists.push(transaction.to);

            if (addressToShares[work.id][transaction.from] == 0) {
                deleteArtist(work.id);
            }

            //delete the transaction id
            deleteTransaction(transactionId);
        }
    }

    function deleteTransaction(uint256 transactionId) private {
        uint256 transactionIndex;

        for (uint256 i = 0; i < _pendingTransactions.length - 1; i++) {
            if (_pendingTransactions[i] == transactionId) {
                transactionIndex = i;
            }

            if (i >= transactionIndex) {
                _pendingTransactions[i] = _pendingTransactions[i + 1];
            }
        }
        delete _pendingTransactions[_pendingTransactions.length - 1];
        _pendingTransactions.pop();
    }

    function deleteArtist(uint256 work_id) private {
        uint8 artistIndex;
        Work storage work = idToWork[work_id];

        for (uint8 i = 0; i < work.artists.length - 1; i++) {
            if (artistsBalance[work.artists[i]] == 0) {
                artistIndex = i;
            }

            if (i >= artistIndex) {
                work.artists[i] = work.artists[i + 1];
            }
        }
        delete work.artists[work.artists.length - 1];
        work.artists.pop();
    }

    function withdraw() public onlyValidBalance {
        address artist = msg.sender;
        payable(artist).transfer(artistsBalance[artist]);
        emit WithdrawFunds(artist, artistsBalance[artist]);
        artistsBalance[artist] = 0;
    }

    /***************
    VIEWS
    ***************/

    function getPendingTransactions() public view returns (uint256[] memory) {
        return _pendingTransactions;
    }

    function getTransaction(uint256 idTx)
        public
        view
        returns (Transaction memory)
    {
        return _transactions[idTx];
    }

    function getAddressToShares(address artist, uint256 work_id)
        public
        view
        returns (uint8)
    {
        return addressToShares[work_id][artist];
    }

    function getArtistsBalance(address artist) public view returns (uint256) {
        return artistsBalance[artist];
    }

    function getArtistsInvolved(uint256 work_id)
        public
        view
        returns (address[] memory)
    {
        Work storage work = idToWork[work_id];
        return work.artists;
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}