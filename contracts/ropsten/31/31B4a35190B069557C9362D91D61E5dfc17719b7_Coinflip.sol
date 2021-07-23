pragma solidity =0.5.16;

import './provableAPI_0.5.sol';
import './SafeMath.sol';

contract Coinflip is usingProvable {
    using SafeMath for uint;

    struct Bet {
        address playerAddress;
        uint betValue;
        uint headsTails;
        uint setRandomPrice;
    }

    mapping(address => uint) public playerWinnings;
    mapping (address => Bet) public waiting;
    mapping (bytes32 => address) public afterWaiting;

    event logNewProvableQuery(string description);
    event sentQueryId(address caller, bytes32 indexed queryId);
    event callbackReceived(bytes32 indexed queryId, string description, uint256 amount);
    event userWithdrawal(address indexed caller, uint256 amount);

    uint public contractBalance;

    uint256 constant GAS_FOR_CALLBACK = 200000;
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;

    address payable public owner = msg.sender;

    bool public freeCallback = true;

    constructor() public payable{
        owner = msg.sender;
        contractBalance = msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function random() public view returns (uint) {
        return now % 2;
    }

    function callback(bytes32 _queryId, string memory _result) public {
        require(msg.sender == provable_cbAddress());

        //turn number into 1 or 0
        uint256 flipResult = SafeMath.mod(uint256(keccak256(abi.encodePacked(_result))), 2);

        //linking new mapping with new struct
        address _player = afterWaiting[_queryId];

        Bet memory postBet = waiting[_player];


        if(flipResult == postBet.headsTails){
            //winner
            uint winAmount = SafeMath.sub(SafeMath.mul(postBet.betValue, 2), postBet.setRandomPrice);
            contractBalance = SafeMath.sub(contractBalance, postBet.betValue);
            playerWinnings[_player] = SafeMath.add(playerWinnings[_player], winAmount);

            /**
            *         @notice The following commented commands mirror the above commands sans SafeMath for readability.
            *
            *          uint winAmount = (postBet.betValue * 2) - postBet.setRandomPrice;
            *          contractBalance -= postBet.betValue;
            *          playerWinnings[_player] += winAmount;
             */

            emit callbackReceived(_queryId, "Winner", postBet.betValue);
        } else {
            //loser
            contractBalance = SafeMath.add(contractBalance, SafeMath.sub(postBet.betValue, postBet.setRandomPrice));
            /**
            *           @notice For readability--see previous comment.
            *
            *          contractBalance += (postBet.betValue - postBet.setRandomPrice);
             */
            emit callbackReceived(_queryId, "Loser", postBet.betValue);
        }
    }

    /**
     *@notice This function simulates a coin flip which makes a call to the Provable oracle for
     *        a random number.
     *@dev The function first checks if this is the very first call to the Provable oracle in order
     *     for the user to not pay for the first free call. This also adds user values to two different
     *     mappings: 'waiting' and 'afterWaiting.' Both mappings are necessary in order to bridge the
     *     user's address (which we has access to here with msg.sender) and the user's queryId sent from
     *     Provable after the function call.
     *
     *@param oneZero - The numerical value of heads(0) or tails(1)
      */

    function flip(uint256 oneZero) public payable {
        require(contractBalance > msg.value, "We don't have enough funds");

        uint256 randomPrice;

        if(freeCallback == false){
            randomPrice = getQueryPrice();
        } else {
            freeCallback = false;
            randomPrice = 0;
        }

        uint256 QUERY_EXECUTION_DELAY = 0;
        bytes32 _queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        emit logNewProvableQuery("Message sent. Waiting for an answer...");
        emit sentQueryId(msg.sender, _queryId);

        uint256 flipResult = block.timestamp %2;

        if(flipResult == 0){

            //winner
            emit callbackReceived(_queryId, "Winner", msg.value);
        } else {

            //loser
            emit callbackReceived(_queryId, "Loser", msg.value);
        }

        Bet memory newBetter;
        newBetter.playerAddress = msg.sender;
        newBetter.betValue = msg.value;
        newBetter.headsTails = oneZero;
        newBetter.setRandomPrice = 0;

        waiting[msg.sender] = newBetter;
    }



    //combine gas and randomTx fee
    function getQueryPrice() internal returns(uint256 _price) {
        _price = provable_getPrice("price", GAS_FOR_CALLBACK);
    }


    function withdrawUserWinnings() public {
        require(playerWinnings[msg.sender] > 0, "No funds to withdraw");
        uint toTransfer = playerWinnings[msg.sender];
        playerWinnings[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
        emit userWithdrawal(msg.sender, toTransfer);
    }

    function getWinningsBalance() public view returns(uint){
        return playerWinnings[msg.sender];
    }

    /**
    *@notice The following functions are reserved for the owner of the contract.
     */

    function fundContract() public payable onlyOwner {
        contractBalance = SafeMath.add(contractBalance, msg.value);
    }

    function fundWinnings() public payable onlyOwner {
        playerWinnings[msg.sender] = SafeMath.add(playerWinnings[msg.sender], msg.value);
    }

    function withdrawAll() public onlyOwner {
        uint toTransfer = contractBalance;
        contractBalance = 0;
        msg.sender.transfer(toTransfer);
    }

}