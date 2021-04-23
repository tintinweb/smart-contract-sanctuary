/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.8.3;

contract NftTreasureHunt {

    // The various stages of the project
    enum State {
        Started,
        RoundOne,
        RoundTwo,
        RoundThree,
        HuntFinished,
        TreasureReleased,
        TeamPaid,
        Failed
    }

    // Contains the current state of the project
    State public state;

    // randomNonce used with keccack for pseudo-random number generation
    uint256 randNonce = 0;

    // Beneficiary/owner to be paid upon project completion
    address payable public beneficiary;
    address payable public owner;

    // Total treasure discovered
    uint public discoveredTreasure;

    // Maximum mintable pirates
    uint256 public MAXIMUM_PIRATES = 6000;
    
    // Total pirates minted
    uint256 public totalPiratesMinted;
    
    
    // Total pirates minted
    uint256 public balance = address(this).balance;
    
    // Structure of a pirate
    struct Pirate {
        address owner;
        uint treasureAmount;
        bool isWinner;
    }
    
    // Structure of a pirate owner
    struct Owner {
        uint256[] pirates;
        uint treasureAmount;
    }

    // Mapping which contains all minted pirates
    mapping(int => Pirate) public pirates;


    // Mapping which contains all owners information
    mapping(address => Owner) public owners;

    // Modifier to restrict invalid state changes
    modifier inState(State expectedState) {
        require(state == expectedState, "Invalid state");
        _;
    }

    // Modifier to prevent minting outside of rounds
    modifier inMintPhase(State currentState) {
        require(
            (currentState == State.Started ||
                currentState == State.RoundOne ||
                currentState == State.RoundTwo ||
                currentState == State.RoundThree),
            "Minting phase has passed - no more pirates may be minted."
        );
        _;
    }

    constructor(address payable _beneficiary) public  {
        beneficiary = _beneficiary;
        state = State.Started;
        owner = payable(msg.sender);
        totalPiratesMinted = 0;
        discoveredTreasure = 0;
    } 

    function mintPirate(uint256 amountToMint) public payable inMintPhase(state)  {
        uint ethPerPirate = 5000000000000000; // .05eth

        require(amountToMint > 0 && amountToMint <= 100, "You may only purchase between 1 and 20 pirates per transaction.");
        require(totalPiratesMinted < MAXIMUM_PIRATES, "All pirates have been minted.");
        require(msg.value >= ethPerPirate * amountToMint, "Price is incorrect.");
        require(totalPiratesMinted + amountToMint <= MAXIMUM_PIRATES, "Not enough pirates in stock.");
        
        // iterate from 1 to amountToMint
        for (uint256 i = 1; i <= amountToMint; i++) {  
            
            // Increase the mint count
            totalPiratesMinted++;
            
            // Update pirate array
            pirates[int256(totalPiratesMinted)].owner = msg.sender;
            pirates[int256(totalPiratesMinted)].isWinner = false;
            pirates[int256(totalPiratesMinted)].treasureAmount = 0;
            
            // Update owner array pirate count
            owners[msg.sender].pirates.push(totalPiratesMinted);
        }

        // Set discovered treasure amount
        discoveredTreasure = ethPerPirate * amountToMint / 2;
        
        
    }

    function beginRoundOne()
        public
        inState(State.Started)
        returns (string memory)
    {
        for (uint i = 0; i < 6; i++) {
          uint256 winner =  pickWinner();
          
          pirates[int256(winner)].isWinner = true;
          pirates[int256(winner)].treasureAmount = 250000000000000000; // .25 eth
                                                   
          owners[pirates[int256(winner)].owner].treasureAmount = owners[pirates[int256(winner)].owner].treasureAmount + 250000000000000000; // .25 eth
          
          discoveredTreasure = discoveredTreasure + 250000000000000000; // .25 eth
        }

        state = State.RoundOne;

    }
    

    

    function beginRoundTwo()
        public
        inState(State.RoundOne)
        returns (string memory)
    {
        for (uint i = 6; i < 12; i++) {
          uint256 winner =  pickWinner();
          
          pirates[int256(winner)].isWinner = true;
          pirates[int256(winner)].treasureAmount = 250000000000000000; // .25 eth
                                                   
          owners[pirates[int256(winner)].owner].treasureAmount = owners[pirates[int256(winner)].owner].treasureAmount + 250000000000000000; // .25 eth
          
          discoveredTreasure = discoveredTreasure + 250000000000000000; // .25 eth
        }


        state = State.RoundTwo;

    }

    function beginRoundThree()
        public
        inState(State.RoundTwo)
    {
        for (uint i = 12; i < 18; i++) {
          uint256 winner =  pickWinner();
          
          pirates[int256(winner)].isWinner = true;
          pirates[int256(winner)].treasureAmount = 250000000000000000; // .25 eth
                                                   
          owners[pirates[int256(winner)].owner].treasureAmount = owners[pirates[int256(winner)].owner].treasureAmount + 250000000000000000; // .25 eth
          
          discoveredTreasure = discoveredTreasure + 250000000000000000; // .25 eth

        }

        state = State.RoundThree;
    }

    function finishHunt()
        public
        inState(State.RoundThree)
    {
     
        for (uint i = 18; i < 24; i++) {
          uint256 winner =  pickWinner();
          
          pirates[int256(winner)].isWinner = true;
          pirates[int256(winner)].treasureAmount = 250000000000000000; // .25 eth
                                                   
          owners[pirates[int256(winner)].owner].treasureAmount = owners[pirates[int256(winner)].owner].treasureAmount + 250000000000000000; // .25 eth
          
          discoveredTreasure = discoveredTreasure + 250000000000000000; // .25 eth

        }
        
        state = State.HuntFinished;
    }


    // TODO - Determine why the first person paid out is the only person paid out
    function claimTreasure()
        public
        inState(State.HuntFinished)
    {

        require(owners[msg.sender].treasureAmount > 0, "No treasure allocated to wallet.");

        address payable sender = payable(msg.sender);

        uint256 winnings = owners[msg.sender].treasureAmount;
        owners[sender].treasureAmount = 0;
        discoveredTreasure = discoveredTreasure - winnings;

        if (!sender.send(winnings)) {
            owners[msg.sender].treasureAmount = winnings;
            discoveredTreasure = discoveredTreasure + winnings;
        }
    }



    // TODO - Separate selfdestruct into its own method, ensure proper checks and
    // balances are in place for sending money.
    function payBeneficiary()
        public
        inState(State.HuntFinished)
    {
        // TODO - REQUIRE
        beneficiary.send(address(this).balance);
        selfdestruct(owner);

    }
    
     
     
    function selfDestruct()
        public
    {
        selfdestruct(owner);
    }
    
    
    
    
    // TODO Replace with chainlink VR - this random number scheme can be gamed
    // by people who run nodes replaying the transaction in transit
        function pickWinner()
        internal
        returns (uint256)
    {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            ) % totalPiratesMinted;
    }

}