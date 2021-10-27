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

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ChanceRoom is Initializable{

///////////// constants /////////////
    string public info;             //summary information about purpose of the room
    string public baseURI;          //source of visual side of room
    uint256 public gateFee;         //price of every single card in wei
    uint256 public commission;      //the wage of contract owner in wei
    uint256 public userLimit;       //maximum number of users can sign in
    uint256 public deadLine;        //when getRandomNumber function unlocks (assuming not reach the quorum of users) 
    address public owner;           //owner of contract
    address public RNC;             //random number consumer address

///////////// variables /////////////
    bool gateIsOpen;                //the contract is open and active now
    string public status;           //status of the room
    uint256 public RNCwithhold;     //withhold cash to activate RNC
    uint256 public userCount;       //number of users signed in till this moment
    uint256 public prize;           //the prize winner wins
    address public winner;          //winner of the room
    
/////////////  mappings  /////////////
    mapping (uint256 => address) public indexToAddr;
    mapping (address => bool) public userEntered;
    
/////////////   events   /////////////
    event SignIn(address user);
    event RollDice(bytes32 requestId);
    event Win(uint256 index, address user, uint256 amount);


///////////// initializer /////////////
    function initialize(
        string memory _info,
        string memory _baseURI,
        uint256 _gateFee,
        uint256 _percentCommission,
        uint256 _userLimit,
        uint256 _timeLimit,
        address _owner,
        address _RandomNumberConsumer
        ) public initializer {
        info = _info;
        baseURI = _baseURI;
        gateFee = _gateFee;
        commission = gateFee * _percentCommission / 100;
        userLimit = _userLimit;
        if (_timeLimit > 0) {
            deadLine = block.timestamp + _timeLimit;
        }
        owner = _owner;
        RNC = _RandomNumberConsumer;
        gateIsOpen = true;
        status = "open and active";
    }


/////////////    modifiers    /////////////
    modifier enterance() {
        require(gateIsOpen, "room expired");
        require(userLimit == 0 || userCount < userLimit, "sold out.");
        require(!userEntered[msg.sender], "signed in before.");
        _;
    }

    modifier canRoll() {
        require(RNCwithhold == RNCfee(), "not enough RNC withhold");
        if(userLimit > 0 && deadLine > 0) {
            require(userCount == userLimit || block.timestamp >= deadLine, "reach time limit or user limit to activate dice");
        } else if (userLimit > 0) {
            require(userCount == userLimit, "reach user limit to activate dice");
        } else if (deadLine > 0) {
            require(block.timestamp >= deadLine, "you have to wait untill deadline pass");
        } else {
            require(msg.sender == owner, "only owner can call this function");
        }
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


///////////// Sub Functions /////////////

    function secondsLeftToRollDice() public view returns(uint256 _secondsLeft) {
        if(deadLine > block.timestamp) {
            return deadLine - block.timestamp;
        } else {return 0;}
    }

    function usersNumberToRollDice() public view returns(uint256 _usersNeeded) {
        if(userLimit > userCount) {
            return userLimit - userCount;
        } else {return 0;}
    }

    function RNCfee() public view returns(uint256) {
        (bool success, bytes memory result) = RNC.staticcall(abi.encodeWithSignature("appFee()"));
        require(success);
        uint256 fee = abi.decode(result, (uint256));
        return (fee);
    }

    function withdrawableSupply() public view returns(uint256){
        uint256 unavailable = RNCwithhold + prize;
        return address(this).balance - unavailable;
    }

    function deductRNCwithhold(uint256 value) private returns(uint256){
        uint256 requiredAmount = RNCfee() - RNCwithhold;
        if(requiredAmount > 0){
            if(requiredAmount >= value){
                RNCwithhold += value;
                value = 0;
            }else{
                RNCwithhold += requiredAmount;
                value -= requiredAmount;
            }
        }
        return value;
    }

    function collectPrize(uint256 value) private {
        if(value > commission) {
            value -= commission;
            prize += value;
        }
    }

    function transferPrize() private {
        address payable reciever = payable(winner);
        reciever.transfer(prize);
        prize = 0;
    }


///////////// Main Functions /////////////

    // every person can enter ChanceRoom by paying gate fee
    // RNC withhold and commission will be deducted from incoming value
    // the rest of payment directly deposits to prize variable
    function signIn() public enterance payable{
        require(msg.value == gateFee, "Wrong card fee entered");

        indexToAddr[userCount] = msg.sender;
        userEntered[msg.sender] = true;
        userCount++;

        uint256 available = deductRNCwithhold(msg.value);
        collectPrize(available);

        emit SignIn(msg.sender);

        if(userCount == userLimit){
            gateIsOpen = false;
            status = "Number of users has reach the quorum.";
        }
    }

    // rollDice can be called whenever deadline passed or number of users reached the qourum
    // if deadline and user limit have been set to zero, only owner of the contract can roll the dice
    // rollDice function will request RandomNumberConsumer for a 30 digits random number
    function rollDice() public canRoll {
        gateIsOpen = false;
        bytes4 selector = bytes4(keccak256(bytes("select(uint256)")));
        (bool success, bytes memory data) = RNC.call{value:RNCwithhold}
            (abi.encodeWithSignature("getRandomNumber(bytes4)", selector));
        require(success, "RNC Call Failed");
        RNCwithhold = 0;
        emit RollDice(abi.decode(data, (bytes32)));
        status = "waiting for random number...";
    }

    // only RandomNumberConsumer can call this function
    // select function uses the 30 digits randomness sent by RNC to select winner address among users
    function select(uint256 randomness) public onlyRNC {
        uint256 randIndex = randomness % userCount;
        winner = indexToAddr[randIndex];
        emit Win(randIndex, winner, prize);
        transferPrize();
        status = "Finished.";
    }

    // withdraw commission by owner of the contract
    function withdrawCommission() public onlyOwner {
        address payable reciever = payable(owner);
        reciever.transfer(withdrawableSupply());
    }


///////////// Assurance Functions /////////////

    // owner can upgrade RNC in special cases
    function upgradeRNC(address _RandomNumberConsumer) public onlyOwner{
        RNC = _RandomNumberConsumer;
    }
    
    // charge contract in special cases  
    function charge() public payable{}

    // cancel the room and transfer user payments back
    function cancel() public onlyOwner {
        require(address(this).balance >= userCount * gateFee, "not enough cash to pay users");
        for(uint256 index = 0; index < userCount; index++) {
            address payable reciever = payable(indexToAddr[index]);
            reciever.transfer(gateFee);
        }
        prize = 0;
        gateIsOpen = false;
        status = "Canceled.";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}