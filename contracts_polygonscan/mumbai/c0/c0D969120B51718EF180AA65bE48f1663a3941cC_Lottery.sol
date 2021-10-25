/**
 *Submitted for verification at polygonscan.com on 2021-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// ======================================================================
//   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
//   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
//   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
//   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
//   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
// ======================================================================
//  ================ Open source smart contract on EVM =================
//   =============== Verify Random Function by ChanLink ===============

contract Lottery{

    address RNC;                    //random number consumer address

///////////// variables /////////////
    bool gateIsOpen;                //the contract is open and active now
    uint256 public userCount;       //number of users signed in till this moment
    uint256 public prize;           //the prize winner wins
    address public winner;          //winner of the game

///////////// constants /////////////
    string public info;             //summary information about purpose of the game
    string public baseURI;          //source of visual side of game
    uint256 public gateFee;         //price of every single card in wei
    uint256 public commission;      //the wage of contract owner in wei
    uint256 public userLimit;       //maximum number of users can sign in
    uint256 public deadLine;        //when getRandomNumber function unlocks (assuming not reach the quorum of users) 
    address public owner;           //owner of contract
    
/////////////  mappings  /////////////
    mapping (uint256 => address) indexToAddr;
    mapping (address => bool) userEntered;
    
/////////////   events   /////////////
    event SignIn(address user);
    event RNCFee(bool getFee, uint256 fee);
    event RollDice(bytes32 requestId);
    event Win(uint256 index, address user, uint256 amount);

///////////// constructor /////////////
    constructor(
        string memory _info,
        string memory _baseURI,
        uint256 _gateFee,
        uint256 _commission,
        uint256 _userLimit,
        uint256 _timeLimit,
        address _owner,
        address _RandomNumberConsumer
        ){
        info = _info;
        baseURI = _baseURI;
        gateFee = _gateFee;
        commission = _commission;
        userLimit = _userLimit;
        if (_timeLimit > 0) {
            deadLine = block.timestamp + _timeLimit;
        }
        owner = _owner;
        RNC = _RandomNumberConsumer;
        gateIsOpen = true;
    }


/////////////    modifiers    /////////////
    modifier enterance() {
        require(gateIsOpen, "game expired");
        require(userLimit == 0 || userCount < userLimit, "sold out.");
        require(!userEntered[msg.sender], "signed in before.");
        _;
    }

    modifier diceActive() {
        if(userLimit > 0 && deadLine > 0) {
            require(userCount == userLimit || block.timestamp >= deadLine, "reach time limit or user limit to activate dice");
        } else if (userLimit > 0) {
            require(userCount == userLimit, "reach user limit to activate dice");
        } else if (deadLine > 0) {
            require(block.timestamp >= deadLine, "you have to wait untill deadline pass");
        } else {
            require(msg.sender == owner, "only owner can call this function");
        }
        gateIsOpen = false;
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    modifier onlyRNC() {
        require(msg.sender == RNC, "caller is not the valid RNC");
        _;
    }


///////////// internal functions /////////////
    function transferPrize() private {
        address payable reciever = payable(winner);
        reciever.transfer(prize);
        prize = 0;
    }

    function RNCfee() public view returns(uint256) {
        (bool success, bytes memory result) = RNC.staticcall(abi.encodeWithSignature("appFee()"));
        require(success);
        uint256 fee = abi.decode(result, (uint256));
        return (fee);
    }

///////////// external functions /////////////

    // every person can enter lottery by paying gate fee
    // commission will be deducted from msg.value and the rest of payment directly deposit to prize
    function signIn() public enterance payable{
        require(msg.value == gateFee, "Wrong card fee entered");

        indexToAddr[userCount] = msg.sender;
        userEntered[msg.sender] = true;
        userCount++;

        prize += (msg.value - commission) ;

        emit SignIn(msg.sender);

        if(userCount == userLimit){gateIsOpen = false;}
    }

    // rollDice can be called whenever deadline passed or number of users reached the qourum
    // rollDice function will request RandomNumberConsumer for a 30 digits random number
    function rollDice() public diceActive {
        bytes4 selector = bytes4(keccak256(bytes("select(uint256)")));
        (bool success, bytes memory data) = RNC.call{value:RNCfee()}
            (abi.encodeWithSignature("getRandomNumber(bytes4)", selector));
        require(success, "RNC Call Failed");
        emit RollDice(abi.decode(data, (bytes32)));
    }

    // only RandomNumberConsumer can call this function
    // select function uses the 30 digits randomness sent by RNC to select winner address among users
    function select(uint256 randomness) public onlyRNC {
        uint256 randIndex = randomness % userCount;
        winner = indexToAddr[randIndex];
        emit Win(randIndex, winner, prize);
        transferPrize();
    }

    // owner can upgrade RNC
    function upgradeRNC(address _RandomNumberConsumer) public onlyOwner{
        RNC = _RandomNumberConsumer;
    }

    // withdraw commission by owner of the contract
    function withdrawCommission() public onlyOwner {
        uint256 amount = address(this).balance - prize;
        address payable reciever = payable(owner);
        reciever.transfer(amount);
    }

    // cancel the game and get back user payments
    function cancel() public onlyOwner {
        require(address(this).balance >= userCount * gateFee, "not enogh cash to pay users");
        for(uint256 index = 0; index < userCount; index++) {
            address payable reciever = payable(indexToAddr[index]);
            reciever.transfer(gateFee);
        }
        prize = 0;
        gateIsOpen = false;
    }
}