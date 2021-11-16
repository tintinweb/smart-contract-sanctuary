/**
 *Submitted for verification at snowtrace.io on 2021-11-16
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface iPEFI is IERC20 {
    function leave(uint256 share) external;
}

contract PenguinDatabase {

    struct PenguinInfo{
        bool isRegistered;
        uint128 style;
        string nickname;
        string color;
    }

    mapping (address => PenguinInfo) public penguDB;
    mapping (string => bool) public nicknameDB;
    mapping (address => uint256) public lastNamechange;


    function nickname(address penguinAddress) external view returns(string memory) {
        return penguDB[penguinAddress].nickname;
    }

    function color(address penguinAddress) external view returns(string memory) {
        return penguDB[penguinAddress].color;
    }

    function isRegistered(address penguinAddress) external view returns(bool) {
        return penguDB[penguinAddress].isRegistered;
    }

    function style(address penguinAddress) external view returns(uint256) {
        return penguDB[penguinAddress].style;
    }

    function canChangeName(address penguinAddress) public view returns(bool) {
        if (lastNamechange[penguinAddress] + 86400 <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function registerYourPenguin(string memory _nickname, string memory _color, uint128 _style) external {
        // Penguins can only register their nickname once. Each nickname must be unique.
       require(penguDB[msg.sender].isRegistered != true);
       require(nicknameDB[_nickname] != true, "Choose a different nickname, that one is already taken.");
       PenguinInfo storage currentPenguinInfo = penguDB[msg.sender];
       currentPenguinInfo.nickname = _nickname;
       currentPenguinInfo.color = _color;
       nicknameDB[_nickname] = true;
       currentPenguinInfo.style = _style;
       currentPenguinInfo.isRegistered = true;
       lastNamechange[msg.sender] = block.timestamp;
    }

    function changeStyle (uint128 _newStyle) external {
        penguDB[msg.sender].style = _newStyle;
    }

    function changeColor (string memory _newColor) external {
        penguDB[msg.sender].color = _newColor;
    }

    function changeNickname (string memory _newNickname) external {
        require(nicknameDB[_newNickname] != true, "Choose a different nickname, that one is already taken.");
        require(canChangeName(msg.sender), "Can only change name once daily");
        string memory currentNickname = penguDB[msg.sender].nickname;
        nicknameDB[currentNickname] = false;
        nicknameDB[_newNickname] = true;
        penguDB[msg.sender].nickname = _newNickname;
        lastNamechange[msg.sender] = block.timestamp;
    }
}

contract OwnableInitialized {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initOwner) {
        require(initOwner != address(0), "Ownable: initOwner is the zero address");
        _owner = initOwner;
        emit OwnershipTransferred(address(0), initOwner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PenguinEmperor is OwnableInitialized {
    struct PlayerInfo {
        //cumulative time spent as emperor
        uint256 timeAsEmperor;
        //last time at which the player became emperor (default 0)
        uint256 lastCrowningBlockTimestamp;
        //number of times the player has stolen the crown
        uint256 timesCrownStolen;
        //most recent timestamp at which player was poisoned (default 0)
        uint256 lastTimePoisoned;
        //last player to poison the player (default 0 address)
        address lastPoisonedBy;
        //number of times the player has been poisoned by another emperor
        uint256 timesPoisoned;
        //number of times the player has poisoned another emperor
        uint256 emperorsPoisoned;
    }

    //PEFI token
    address public constant PEFI = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;
    //iPEFI token
    address public constant NEST = 0xE9476e16FE488B90ada9Ab5C7c2ADa81014Ba9Ee;
    //token used for play
    address public immutable TOKEN_TO_PLAY;
    //used for intermediate token management if not playing with PEFI or iPEFI
    address public immutable NEST_ALLOCATOR;
    //database for users to register their penguins
    address public immutable penguinDatabase;
    //see usage in poisonCost() function
    uint256 public constant MAX_POISON_BIPS_FEE = 1000;
    //constant for calculations that use BIPS
    uint256 internal constant MAX_BIPS = 10000;

    //address and bid amount of current emperor
    address public currentEmperor;
    uint256 public currentEmperorBid;

    //amount of each bid that goes to the jackpot & nest, in BIPS
    uint256 public immutable jackpotFeeBIPS;
    uint256 public immutable nestFeeBIPS;
    //current jackpot size in TOKEN_TO_PLAY
    uint256 public jackpot;
    //total TOKEN_TO_PLAY sent to NEST
    uint256 public totalNestDistribution;

    //game settings. times in (UTC) seconds, bid + fee amounts in wei
    uint256 public startDate;
    uint256 public finalDate;
    uint256 public immutable openingBid;
    uint256 public immutable minBidIncrease;
    uint256 public immutable maxBidIncrease;
    uint256 public immutable poisonFixedFee;
    uint256 public immutable poisonBipsFee;
    uint256 public immutable poisonDuration;
    uint256 public immutable poisonCooldown;
    uint256 public immutable poisonSplitToNest;
    uint256 public immutable poisonSplitToJackpot;

    //total number of times the crown was stolen this game
    uint256 public totalTimesCrownStolen;
    //whether or not the game's jackpot has been distributed yet
    bool public jackpotClaimed;

    //variables for top emperors
    uint256 public immutable NUMBER_TOP_EMPERORS;
    address[] public topEmperors;
    uint256[] public longestReigns;
    uint256[] public JACKPOT_SPLIT;

    //optional extra mechanic to ocassionally distribute tokens
    bool public immutable randomDistributorEnabled;

    //optional extra mechanic to add to the game's duration each time the crown is stolen
    uint256 constant internal MAX_TIME_TO_ADD_ON_STEAL = 120;
    uint256 public immutable timeToAddOnSteal;
    bool public immutable addTimeOnStealEnabled;

    //stores info for each player
    mapping(address => PlayerInfo) public playerDB;

    event CrownStolen(address indexed newEmperor);
    event SentToNest(uint256 amountTokens);
    event JackpotClaimed(uint256 jackpotSize);
    event EmperorPoisoned(address indexed poisonedEmperor, address indexed poisoner, uint256 timePoisoned);

    modifier stealCrownCheck() {
        /*Checks for the following conditions:
        A. Check to see that the competiton is ongoing
        B. The msg.sender registered their Penguin.
        C. The msg.sender isn't the current Emperor.
        D. The bid is enough to dethrone the currentEmperor.
        E. Sender is not a contract
        F. Sender was not recently poisoned.
        */
        require(isGameRunning(), "Competition is not ongoing.");
        require(PenguinDatabase(penguinDatabase).isRegistered(msg.sender), "Please register your Penguin first.");
        require(msg.sender != currentEmperor, "You are already the King of Penguins.");
        require(msg.sender == tx.origin, "EOAs only");
        require(block.timestamp >= (playerDB[msg.sender].lastTimePoisoned + poisonDuration), "You were poisoned too recently");
        _;
    } 

    //see below for how the variables are assigned to the arrays
    //address[4] memory _addressParameters = [TOKEN_TO_PLAY, NEST_ALLOCATOR, penguinDatabase, owner]
    //uint256[] memory _JACKPOT_SPLIT = bips that each top emperor gets (beginning with the one with the longest reign)
    //uint256[3] memory _bidParameters = [openingBid, minBidIncrease, maxBidIncrease]
    //uint256[6] memory _poisonParameter = [poisonFixedFee, poisonBipsFee, poisonDuration, poisonCooldown, poisonSplitToNest, poisonSplitToJackpot]
    //bool[2] memory _optionalMechanics = [randomDistributorEnabled, addTimeOnStealEnabled]
    constructor (
        uint256 _jackpotFeeBIPS,
        uint256 _nestFeeBIPS,
        uint256 _startDate,
        uint256 _competitionDuration,
        uint256 _NUMBER_TOP_EMPERORS,
        address[4] memory _addressParameters,
        uint256[] memory _JACKPOT_SPLIT,
        uint256[3] memory _bidParameters,
        uint256[6] memory _poisonParameters,
        bool[2] memory _optionalMechanics,
        uint256 _timeToAddOnSteal)
        OwnableInitialized(_addressParameters[3]) {
        require(_NUMBER_TOP_EMPERORS > 0, "must have at least 1 top emperor");
        require(_JACKPOT_SPLIT.length == _NUMBER_TOP_EMPERORS, "wrong length of _JACKPOT_SPLIT input");
        //local parameter since immutable variables can't be read inside the constructor
        uint256 numTopEmperors = _NUMBER_TOP_EMPERORS;
        NUMBER_TOP_EMPERORS = _NUMBER_TOP_EMPERORS;
        uint256 jackpotTotal;
        for(uint256 i = 0; i < numTopEmperors; i++) {
            jackpotTotal += _JACKPOT_SPLIT[i];
        }
        require(_startDate > block.timestamp, "game must start in future");
        require(jackpotTotal == MAX_BIPS, "bad JACKPOT_SPLIT input");
        require(_poisonParameters[4] + _poisonParameters[5] == MAX_BIPS, "bad poisonSplit inputs");
        require(_poisonParameters[1] <= MAX_POISON_BIPS_FEE, "bad poisonBipsFee inpupt");
        require(_bidParameters[1] <= _bidParameters[2], "invalid bidIncrease values"); 
        require(_addressParameters[0] != address(0) && _addressParameters[1] != address(0)
            && _addressParameters[2] != address(0) && _addressParameters[3] != address(0), "bad address input");
        require(_timeToAddOnSteal <= MAX_TIME_TO_ADD_ON_STEAL, "timeToAddOnSteal too large");
        TOKEN_TO_PLAY = _addressParameters[0];
        NEST_ALLOCATOR = _addressParameters[1];
        penguinDatabase = _addressParameters[2];
        startDate = _startDate;
        finalDate = _startDate + _competitionDuration;
        jackpotFeeBIPS = _jackpotFeeBIPS;
        topEmperors = new address[](_NUMBER_TOP_EMPERORS);
        longestReigns = new uint256[](_NUMBER_TOP_EMPERORS);
        JACKPOT_SPLIT = _JACKPOT_SPLIT;
        nestFeeBIPS = _nestFeeBIPS;
        openingBid = _bidParameters[0];
        minBidIncrease = _bidParameters[1];
        maxBidIncrease = _bidParameters[2];
        poisonFixedFee = _poisonParameters[0];
        poisonBipsFee = _poisonParameters[1];
        poisonDuration = _poisonParameters[2];
        poisonCooldown = _poisonParameters[3];
        poisonSplitToNest = _poisonParameters[4];
        poisonSplitToJackpot = _poisonParameters[5];
        randomDistributorEnabled = _optionalMechanics[0];
        timeToAddOnSteal = _timeToAddOnSteal;
        addTimeOnStealEnabled = _optionalMechanics[1];
    }

    //PUBLIC VIEW FUNCTIONS
    //gets contract AVAX balance, to be split amongst winners
    function avaxJackpot() public view returns(uint256) {
        return address(this).balance;
    }

    //returns the current cost of poisoning the emperor
    function poisonCost() public view returns(uint256) {
        return ((currentEmperorBid * poisonBipsFee) / MAX_BIPS) + poisonFixedFee;
    }

    //returns nickname of the current emperor
    function getCurrentEmperorNickname() view public returns (string memory) {
        return PenguinDatabase(penguinDatabase).nickname(currentEmperor);
    }

    //whether or not 'penguinAddress' can be poisoned at the present moment
    function canBePoisoned(address penguinAddress) public view returns(bool) {
        if (block.timestamp >= (playerDB[penguinAddress].lastTimePoisoned + poisonCooldown)) {
            return true;
        } else {
            return false;
        }
    }

    //remaining time until 'penguinAddress' can be poisoned again
    function timeLeftForPoison(address penguinAddress) view public returns(uint256) {
        if (block.timestamp >= (playerDB[penguinAddress].lastTimePoisoned + poisonCooldown)) {
            return 0;
        } else {
            return ((playerDB[penguinAddress].lastTimePoisoned + poisonCooldown) - block.timestamp);
        }
    }   

    //remaining time that 'penguinAddress' is poisoned
    function timePoisonedRemaining(address penguinAddress) view public returns(uint256) {
        if (block.timestamp >= (playerDB[penguinAddress].lastTimePoisoned + poisonDuration)) {
            return 0;
        } else {
            return ((playerDB[penguinAddress].lastTimePoisoned + poisonDuration) - block.timestamp);
        }
    }

    //returns 'true' only if the game is open for play
    function isGameRunning() view public returns(bool) {
        return(block.timestamp >= startDate && block.timestamp <= finalDate);
    }

    //returns 0 if game is not running, otherwise returns the amount of seconds left to play
    function timeUntilEnd() view public returns(uint256) {
        if(!isGameRunning()) {
            return 0;
        } else {
            return(finalDate - block.timestamp);
        }
    }

    //returns 0 if the game start has passed, otherwise returns the amount of seconds left until the game starts
    function gameStartIn() view public returns(uint256) {
        if (block.timestamp >= startDate) {
            return 0;
        } else {
            return (startDate - block.timestamp);
        }
    }

    //includes the time that the current emperor has held the throne
    function timeAsEmperor(address penguinAddress) view public returns(uint256) {
        if (penguinAddress != currentEmperor || jackpotClaimed) {
            return playerDB[penguinAddress].timeAsEmperor;
        } else if (!isGameRunning()) {
            return (playerDB[penguinAddress].timeAsEmperor + (finalDate - playerDB[penguinAddress].lastCrowningBlockTimestamp));
        } else {
            return (playerDB[penguinAddress].timeAsEmperor + (block.timestamp - playerDB[penguinAddress].lastCrowningBlockTimestamp));
        }
    }

    //EXTERNAL FUNCTIONS
    function stealCrown(uint256 amount) external stealCrownCheck() {
        //transfer TOKEN_TO_PLAY from the new emperor to this contract
        IERC20(TOKEN_TO_PLAY).transferFrom(msg.sender, address(this), amount);
        _stealCrown(amount);
    }

    function stealCrownAndPoison(uint256 amount) external stealCrownCheck() {
        require(canBePoisoned(currentEmperor), "This emperor was already recently poisoned");
        uint256 currentPoisonCost = poisonCost();
        //transfer TOKEN_TO_PLAY from the new emperor to this contract
        IERC20(TOKEN_TO_PLAY).transferFrom(msg.sender, address(this), (amount + currentPoisonCost));
        playerDB[currentEmperor].lastTimePoisoned = block.timestamp;
        playerDB[currentEmperor].lastPoisonedBy = msg.sender;
        playerDB[currentEmperor].timesPoisoned += 1;
        playerDB[msg.sender].emperorsPoisoned += 1;
        emit EmperorPoisoned(currentEmperor, msg.sender, block.timestamp);
        totalNestDistribution += ((currentPoisonCost * poisonSplitToNest) / MAX_BIPS);
        jackpot += ((currentPoisonCost * poisonSplitToJackpot) / MAX_BIPS);
        _stealCrown(amount);
    }

    function claimJackpot() external {
        require(block.timestamp > finalDate, "Competition still running");
        require(!jackpotClaimed, "Jackpot already claimed");
        jackpotClaimed = true;
        emit JackpotClaimed(jackpot);

        //Keeps track of the time (in seconds) for which the lastEmperor held the crown.
        //nearly identical to logic above, but uses finalDate instead of block.timestamp
        playerDB[currentEmperor].timeAsEmperor += (finalDate - playerDB[currentEmperor].lastCrowningBlockTimestamp);    

        //Checks to see if the final Emperor is within the top NUMBER_TOP_EMPERORS (in terms of total time as Emperor)
        _updateTopEmperors(currentEmperor);

        //update AVAX jackpot, to handle if any simple transfers have been made to the contract
        uint256 avaxJackpotSize = avaxJackpot();

        //distribute funds to nest
        _sendToNest(totalNestDistribution);

        //split jackpot among top NUMBER_TOP_EMPERORS emperors
        for(uint256 i = 0; i < NUMBER_TOP_EMPERORS; i++) {
            address recipient = topEmperors[i];
            //deal with edge case present in testing where less than NUMBER_TOP_EMPERORS addresses have played
            if (recipient == address(0)) {
                recipient = owner();
            }
            _safeTokenTransfer(TOKEN_TO_PLAY, recipient, ((jackpot * JACKPOT_SPLIT[i]) / MAX_BIPS));
            _transferAVAX(recipient, ((avaxJackpotSize * JACKPOT_SPLIT[i]) / MAX_BIPS));
        }   

        //refund last bid
        _safeTokenTransfer(TOKEN_TO_PLAY, currentEmperor, currentEmperorBid);
    }

    //simple function for accepting AVAX transfers directly to the contract -- allows increasing avaxJackpot
    receive() external payable {}

    //OWNER-ONLY FUNCTIONS
    function changeFinalDate(uint256 _finalDate) external onlyOwner {
        require(!isGameRunning(), "Cannot modify while game is running");
        finalDate = _finalDate;
    }   

    function changeStartDate(uint256 _startDate) external onlyOwner {
        require(!isGameRunning(), "Cannot modify while game is running");
        startDate = _startDate;
    }

    function stuckTokenRetrieval(address token, uint256 amount, address dest) external onlyOwner {
        require(block.timestamp > finalDate + 10800, "The competiton must be over");
        _safeTokenTransfer(token, dest, amount);
    }   

    //INTERNAL FUNCTIONS
    function _stealCrown(uint256 _amount) internal {
        if(currentEmperor == address(0)) {
            require(_amount == openingBid, "must match openingBid");
        } else {
            require(_amount >= (currentEmperorBid + minBidIncrease) && _amount <= (currentEmperorBid + maxBidIncrease), "Bad bid");   

            uint256 lastEmperorBidMinusFees = (currentEmperorBid * (MAX_BIPS - (jackpotFeeBIPS + nestFeeBIPS))) / MAX_BIPS;
            uint256 lastEmperorBidFeeForJackpot = (currentEmperorBid * jackpotFeeBIPS) / MAX_BIPS;
            uint256 lastEmperorBidFeeForNests = (currentEmperorBid * nestFeeBIPS) / MAX_BIPS;    

            //Keeps track of the time (in seconds) for which the lastEmperor held the crown.
            playerDB[currentEmperor].timeAsEmperor += (block.timestamp - playerDB[currentEmperor].lastCrowningBlockTimestamp);  

            //Checks to see if the last Emperor is within the top NUMBER_TOP_EMPERORS (in terms of total time as Emperor)
            _updateTopEmperors(currentEmperor); 

            //track NEST distribution
            totalNestDistribution += lastEmperorBidFeeForNests; 

            //transfer TOKEN_TO_PLAY to the previous emperor
            _safeTokenTransfer(TOKEN_TO_PLAY, currentEmperor, lastEmperorBidMinusFees);
            jackpot += lastEmperorBidFeeForJackpot; 

            //tracking for stats
            playerDB[msg.sender].timesCrownStolen += 1;
            totalTimesCrownStolen += 1;

            //trigger random roll, if mechanic is enabled
            if (randomDistributorEnabled) {
                PenguinEmperorManager(payable(owner())).roll(msg.sender);
            }

            //add time on steal, if mechanic is enabled
            if (addTimeOnStealEnabled) {
                finalDate += timeToAddOnSteal;
            }
        }   

        //update currentEmperor, bid amount, and last crowning time
        currentEmperor = msg.sender;
        currentEmperorBid = _amount;
        playerDB[msg.sender].lastCrowningBlockTimestamp = block.timestamp;
        emit CrownStolen(msg.sender);
    }

    function _updateTopEmperors(address lastEmperor) internal {
        uint256 newReign = playerDB[lastEmperor].timeAsEmperor; 

        //short-circuit logic to skip steps if user will not be in top emperors array
        if (longestReigns[(NUMBER_TOP_EMPERORS - 1)] >= newReign) {
            return;
        }

        //check if emperor already in list -- fetch index if they are
        uint256 i = 0;
        bool alreadyInList;
        for(i; i < NUMBER_TOP_EMPERORS; i++) {
            if(topEmperors[i] == lastEmperor) {
                alreadyInList = true;
                break;
            }
        }   

        //get the index of the new element
        uint256 j = 0;
        for(j; j < NUMBER_TOP_EMPERORS; j++) {
            if(longestReigns[j] < newReign) {
                break;
            }
        }   

        if (!alreadyInList) {
            //shift the array down by one position, as necessary
            for(uint256 k = (NUMBER_TOP_EMPERORS - 1); k > j; k--) {
                longestReigns[k] = longestReigns[k - 1];
                topEmperors[k] = topEmperors[k - 1];
            //add in the new element, but only if it belongs in the array
            } if(j < (NUMBER_TOP_EMPERORS - 1)) {
                longestReigns[j] =  newReign;
                topEmperors[j] =  lastEmperor;
            //update last array item in edge case where new newReign is only larger than the smallest stored value
            } else if (longestReigns[(NUMBER_TOP_EMPERORS - 1)] < newReign) {
                longestReigns[j] =  newReign;
                topEmperors[j] =  lastEmperor;
            }   

        //case handling for when emperor already holds a spot
        //check i>=j for the edge case of updates to tied positions
        } else if (i >= j) {
            //shift the array by one position, until the emperor's previous spot is overwritten
            for(uint256 m = i; m > j; m--) {
                longestReigns[m] = longestReigns[m - 1];
                topEmperors[m] = topEmperors[m - 1];
            }
            //add emperor back into array, in appropriate position
            longestReigns[j] =  newReign;
            topEmperors[j] =  lastEmperor;  

        //handle tie edge cases
        } else {
            //just need to update emperor's reign in this case
            longestReigns[i] = newReign;
        }
    }

    function _sendToNest(uint256 amount) internal {
        if (TOKEN_TO_PLAY == NEST) {
            iPEFI(NEST).leave(amount);
            uint256 pefiToSend = IERC20(PEFI).balanceOf(address(this));
            IERC20(PEFI).transfer(NEST, pefiToSend);
            emit SentToNest(pefiToSend);
        } else if (TOKEN_TO_PLAY == PEFI) {
            _safeTokenTransfer(PEFI, NEST, amount);
            emit SentToNest(amount);
        } else {
            _safeTokenTransfer(TOKEN_TO_PLAY, NEST_ALLOCATOR, amount);
            emit SentToNest(amount);
        }
    }   

    function _safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            _transferAVAX(_to, _amount);
        } else {
            uint256 tokenBal =  IERC20(token).balanceOf(address(this));
            bool transferSuccess = false;
            if (_amount > tokenBal) {
                transferSuccess = IERC20(token).transfer(_to, tokenBal);
            } else {
                transferSuccess = IERC20(token).transfer(_to, _amount);
            }
            require(transferSuccess, "_safeTokenTransfer: transfer failed");            
        }
    }

    function _transferAVAX(address _to, uint256 _amount) internal {
        //skip transfer if amount is zero
        if (_amount != 0) {
            uint256 avaxBal = address(this).balance;
            if (_amount > avaxBal) {
                payable(_to).transfer(avaxBal);
            } else {
                payable(_to).transfer(_amount);
            }
        }
    }
}

interface IRandomDistributor {
    function roll(address) external;
    function recoverERC20(IERC20 token, address dest) external;
}

contract PenguinEmperorManager is OwnableInitialized {
    //token used for play
    address public TOKEN_TO_PLAY;
    //used for intermediate token management if not playing with PEFI or iPEFI
    address public NEST_ALLOCATOR;
    //database for users to register their penguins
    address public penguinDatabase;
    //see usage in poisonCost() function
    uint256 public constant MAX_POISON_BIPS_FEE = 1000;
    //constant for calculations that use BIPS
    uint256 internal constant MAX_BIPS = 10000;

    //amount of each bid that goes to the jackpot & nest, in BIPS
    uint256 public jackpotFeeBIPS;
    uint256 public nestFeeBIPS;

    //game settings. times in (UTC) seconds, bid + fee amounts in wei
    uint256 public competitionDuration;
    uint256[3] bidParameters;
    uint256[6] poisonParameters;

    //variables for top emperors
    uint256 public NUMBER_TOP_EMPERORS;
    uint256[] public JACKPOT_SPLIT;

    //array of all games. new games are added as they are created.
    address[] public allGames;

    //optional extra mechanic to ocassionally distribute tokens
    address private randomDistributor;
    bool public randomDistributorEnabled;

    //optional extra mechanic to add to the game's duration each time the crown is stolen
    uint256 constant internal MAX_TIME_TO_ADD_ON_STEAL = 120;
    uint256 public timeToAddOnSteal;
    bool public addTimeOnStealEnabled;

    //see below for how the variables are assigned to the arrays
    //address[4] memory _addressParameters = [TOKEN_TO_PLAY, NEST_ALLOCATOR, penguinDatabase, owner]
    //uint256[] memory _JACKPOT_SPLIT = bips that each top emperor gets (beginning with the one with the longest reign)
    //uint256[3] memory _bidParameters = [openingBid, minBidIncrease, maxBidIncrease]
    //uint256[6] memory _poisonParameter = [poisonFixedFee, poisonBipsFee, poisonDuration, poisonCooldown, poisonSplitToNest, poisonSplitToJackpot]
    constructor (
        uint256 _jackpotFeeBIPS,
        uint256 _nestFeeBIPS,
        uint256 _competitionDuration,
        uint256 _NUMBER_TOP_EMPERORS,
        address[4] memory _addressParameters,
        uint256[] memory _JACKPOT_SPLIT,
        uint256[3] memory _bidParameters,
        uint256[6] memory _poisonParameters)
        OwnableInitialized(_addressParameters[3]) {
        require(_NUMBER_TOP_EMPERORS > 0, "must have at least 1 top emperor");
        uint256 numTopEmperors = _NUMBER_TOP_EMPERORS;
        require(_JACKPOT_SPLIT.length == _NUMBER_TOP_EMPERORS, "wrong length of _JACKPOT_SPLIT input");
        NUMBER_TOP_EMPERORS = _NUMBER_TOP_EMPERORS;
        uint256 jackpotTotal;
        for(uint256 i = 0; i < numTopEmperors; i++) {
            jackpotTotal += _JACKPOT_SPLIT[i];
        }
        require(jackpotTotal == MAX_BIPS, "bad JACKPOT_SPLIT input");
        require(_poisonParameters[4] + _poisonParameters[5] == MAX_BIPS, "bad poisonSplit inputs");
        require(_poisonParameters[1] <= MAX_POISON_BIPS_FEE, "bad poisonBipsFee inpupt");
        require(_bidParameters[1] <= _bidParameters[2], "invalid bidIncrease values"); 
        require(_addressParameters[0] != address(0) && _addressParameters[1] != address(0)
            && _addressParameters[2] != address(0) && _addressParameters[3] != address(0), "bad address input");
        TOKEN_TO_PLAY = _addressParameters[0];
        NEST_ALLOCATOR = _addressParameters[1];
        penguinDatabase = _addressParameters[2];
        competitionDuration = _competitionDuration;
        jackpotFeeBIPS = _jackpotFeeBIPS;
        nestFeeBIPS = _nestFeeBIPS;
        JACKPOT_SPLIT = _JACKPOT_SPLIT;
        bidParameters = _bidParameters;
        poisonParameters = _poisonParameters;
    }

    function numberOfGames() public view returns(uint256) {
        return allGames.length;
    }

    function currentGame() public view returns(address) {
        return allGames[numberOfGames() - 1];
    }

    function createNewGame(uint256 _startDate) external onlyOwner returns(address) {
        require(_startDate > block.timestamp, "game must start in future");
        if (numberOfGames() > 0) {
            require(PenguinEmperor(payable(currentGame())).jackpotClaimed(), "previous game not yet resolved");
        }
        address[4] memory _addressParameters = [TOKEN_TO_PLAY, NEST_ALLOCATOR, penguinDatabase, address(this)];
        bool[2] memory _optionalMechanics = [randomDistributorEnabled, addTimeOnStealEnabled];
        PenguinEmperor newGame = new PenguinEmperor(
            jackpotFeeBIPS,
            nestFeeBIPS,
            _startDate,
            competitionDuration,
            NUMBER_TOP_EMPERORS,
            _addressParameters,
            JACKPOT_SPLIT,
            bidParameters,
            poisonParameters,
            _optionalMechanics,
            timeToAddOnSteal
        );
        allGames.push(address(newGame));
        return address(newGame);
    }

    function changePenguinDatabase(address _penguinDatabase) external onlyOwner {
        penguinDatabase = _penguinDatabase;
    }

    function modifyJackpotAndNestFeeBIPS(uint256 _jackpotFeeBIPS, uint256 _nestFeeBIPS) external onlyOwner {
        jackpotFeeBIPS = _jackpotFeeBIPS;
        nestFeeBIPS = _nestFeeBIPS;
    }   

    function modifyCompetitionDuration(uint256 _competitionDuration) external onlyOwner {
        competitionDuration = _competitionDuration;
    }

    function modifyNUMBER_TOP_EMPERORSAndJACKPOT_SPLIT(uint256 _NUMBER_TOP_EMPERORS, uint256[] memory _JACKPOT_SPLIT) external onlyOwner {
        require(_NUMBER_TOP_EMPERORS > 0, "must have at least 1 top emperor");
        require(_JACKPOT_SPLIT.length == _NUMBER_TOP_EMPERORS, "wrong length of _JACKPOT_SPLIT input");
        uint256 jackpotTotal;
        for(uint256 i = 0; i < _NUMBER_TOP_EMPERORS; i++) {
            jackpotTotal += _JACKPOT_SPLIT[i];
        }
        require(jackpotTotal == MAX_BIPS, "bad JACKPOT_SPLIT input");
        NUMBER_TOP_EMPERORS = _NUMBER_TOP_EMPERORS;   
        JACKPOT_SPLIT = _JACKPOT_SPLIT;
    }

    function modifyTOKEN_TO_PLAY(address _TOKEN_TO_PLAY) external onlyOwner {
        require(_TOKEN_TO_PLAY != address(0), "bad input");
        TOKEN_TO_PLAY = _TOKEN_TO_PLAY;   
    }

    function modifyNEST_ALLOCATOR(address _NEST_ALLOCATOR) external onlyOwner {
        require(_NEST_ALLOCATOR != address(0), "bad input");
        NEST_ALLOCATOR = _NEST_ALLOCATOR;   
    }

    function modifyBidParameters(uint256[3] memory _bidParameters) external onlyOwner {
        require(_bidParameters[1] <= _bidParameters[2], "invalid bidIncrease values"); 
        bidParameters = _bidParameters;  
    }

    function modifyPoisonParameters(uint256[6] memory _poisonParameters) external onlyOwner {
        require(_poisonParameters[4] + _poisonParameters[5] == MAX_BIPS, "bad poisonSplit inputs");
        require(_poisonParameters[1] <= MAX_POISON_BIPS_FEE, "bad poisonBipsFee inpupt");
        poisonParameters = _poisonParameters;
    }

    function modifyRandomDistributor(address _randomDistributor) external onlyOwner {
        randomDistributor = _randomDistributor;
    }

    function modifyRandomDistributorEnabled(bool _randomDistributorEnabled) external onlyOwner {
        randomDistributorEnabled = _randomDistributorEnabled;
    }

    function modifyTimeToAddOnSteal(uint256 _timeToAddOnSteal) external onlyOwner {
        require(_timeToAddOnSteal <= MAX_TIME_TO_ADD_ON_STEAL, "timeToAddOnSteal too large");
        timeToAddOnSteal = _timeToAddOnSteal;
    }

    function modifyAddTimeOnSteal(bool _addTimeOnStealEnabled) external onlyOwner {
        addTimeOnStealEnabled = _addTimeOnStealEnabled;
    }

    function recoverERC20FromDistributor(address _randomDistributor, IERC20 token, address dest) external onlyOwner {
        IRandomDistributor(_randomDistributor).recoverERC20(token, dest);
    } 

    function stuckTokenRetrieval(address token, uint256 amount, address dest) external onlyOwner {
        _safeTokenTransfer(token, dest, amount);
    }   

    function changeStartDate(uint256 _startDate) external onlyOwner {
        PenguinEmperor(payable(currentGame())).changeStartDate(_startDate);
    }

    function changeFinalDate(uint256 _finalDate) external onlyOwner {
        PenguinEmperor(payable(currentGame())).changeFinalDate(_finalDate);
    }

    function stuckTokenRetrieval(address penguinEmperor, address token, uint256 amount, address dest) external onlyOwner {
        PenguinEmperor(payable(penguinEmperor)).stuckTokenRetrieval(token, amount, dest);
    }   

    //simple function for accepting AVAX transfers directly to the contract -- allows recovering AVAX in edge cases
    receive() external payable {}

    function roll(address caller) external {
        if (msg.sender == currentGame() && randomDistributorEnabled) {
            IRandomDistributor(randomDistributor).roll(caller);
        } 
    }

    function _safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            _transferAVAX(_to, _amount);
        } else {
            uint256 tokenBal =  IERC20(token).balanceOf(address(this));
            bool transferSuccess = false;
            if (_amount > tokenBal) {
                transferSuccess = IERC20(token).transfer(_to, tokenBal);
            } else {
                transferSuccess = IERC20(token).transfer(_to, _amount);
            }
            require(transferSuccess, "_safeTokenTransfer: transfer failed");            
        }
    }

    function _transferAVAX(address _to, uint256 _amount) internal {
        //skip transfer if amount is zero
        if (_amount != 0) {
            uint256 avaxBal = address(this).balance;
            if (_amount > avaxBal) {
                payable(_to).transfer(avaxBal);
            } else {
                payable(_to).transfer(_amount);
            }
        }
    }
}

contract RandomDistributorERC20 is OwnableInitialized(msg.sender) {
    address public tokenToDistribute;
    uint256 public amountToDistribute;
    uint256 private previousRandomNumber;
    uint256 private chanceToWin;
    address private roller;

    event Winner(address indexed penguinAddress, uint256 timestamp);

    constructor(address _tokenToDistribute, uint256 _amountToDistribute, uint256 _randomNumberSeed, uint256 _chanceToWin, address _roller) {
        tokenToDistribute = _tokenToDistribute;
        amountToDistribute = _amountToDistribute;
        previousRandomNumber = _randomNumberSeed;
        chanceToWin = _chanceToWin;
        roller = _roller;
    }

    function roll(address caller) external {
        require(msg.sender == roller);
        uint256 randomNumber = _newRandomNumber(caller);
        if ((randomNumber % chanceToWin) == 0) {
            _safeTokenTransfer(tokenToDistribute, caller, amountToDistribute);
            emit Winner(caller, block.timestamp);
        }
    }

    function setParameters(address _tokenToDistribute, uint256 _amountToDistribute, uint256 _chanceToWin, address _roller) external onlyOwner {
        require(_chanceToWin > 0, "bad input");
        tokenToDistribute = _tokenToDistribute;
        amountToDistribute = _amountToDistribute;
        chanceToWin = _chanceToWin;
        roller = _roller;
    }

    //simple function for accepting AVAX transfers directly to the contract
    receive() external payable {}

    function recoverERC20(address token, address dest, uint256 amount) external onlyOwner {
        _safeTokenTransfer(token, dest, amount);
    }

    function _getRandomNumber(address caller) internal view returns(uint256) {
        return uint256( keccak256(abi.encode(caller, block.timestamp, gasleft(), previousRandomNumber, blockhash(block.number - 99))) );
    }

    function _newRandomNumber(address caller) internal returns(uint256) {
        uint256 randomNumber = _getRandomNumber(caller);
        previousRandomNumber = randomNumber;
        return randomNumber;
    }

    function _safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            _transferAVAX(_to, _amount);
        } else {
            uint256 tokenBal =  IERC20(token).balanceOf(address(this));
            bool transferSuccess = false;
            if (_amount > tokenBal) {
                transferSuccess = IERC20(token).transfer(_to, tokenBal);
            } else {
                transferSuccess = IERC20(token).transfer(_to, _amount);
            }
            require(transferSuccess, "_safeTokenTransfer: transfer failed");            
        }
    }

    function _transferAVAX(address _to, uint256 _amount) internal {
        //skip transfer if amount is zero
        if (_amount != 0) {
            uint256 avaxBal = address(this).balance;
            if (_amount > avaxBal) {
                payable(_to).transfer(avaxBal);
            } else {
                payable(_to).transfer(_amount);
            }
        }
    }
}

interface IMintableERC721 {
    function mint(address to) external;
}

contract RandomDistributorNFT is OwnableInitialized(msg.sender) {
    IMintableERC721 public nftToDistribute;
    uint256 private previousRandomNumber;
    uint256 private chanceToWin;
    address private roller;

    event Winner(address indexed penguinAddress, uint256 timestamp);

    constructor(IMintableERC721 _nftToDistribute, uint256 _randomNumberSeed, uint256 _chanceToWin, address _roller) {
        nftToDistribute = _nftToDistribute;
        previousRandomNumber = _randomNumberSeed;
        chanceToWin = _chanceToWin;
        roller = _roller;
    }

    function roll(address caller) external {
        require(msg.sender == roller);
        uint256 randomNumber = _newRandomNumber(caller);
        if ((randomNumber % chanceToWin) == 0) {
            _distributeNFT(caller);
            emit Winner(caller, block.timestamp);
        }
    }

    function setParameters(IMintableERC721 _nftToDistribute, uint256 _chanceToWin, address _roller) external onlyOwner {
        require(_chanceToWin > 0, "bad input");
        nftToDistribute = _nftToDistribute;
        chanceToWin = _chanceToWin;
        roller = _roller;
    }

    function recoverERC20(IERC20 token, address dest) external onlyOwner {
    }

    function _getRandomNumber(address caller) internal view returns(uint256) {
        return uint256( keccak256(abi.encode(caller, block.timestamp, gasleft(), previousRandomNumber, blockhash(block.number - 99))) );
    }

    function _newRandomNumber(address caller) internal returns(uint256) {
        uint256 randomNumber = _getRandomNumber(caller);
        previousRandomNumber = randomNumber;
        return randomNumber;
    }

    function _distributeNFT(address caller) internal {
        nftToDistribute.mint(caller);
    }
}