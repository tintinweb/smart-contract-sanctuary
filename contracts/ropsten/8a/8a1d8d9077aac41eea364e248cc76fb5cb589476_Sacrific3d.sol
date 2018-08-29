pragma solidity ^0.4.24;

contract Sacrific3d {
    
    uint8 constant public PLAYERS_PER_ROUND = 5;
    uint256 constant public SACRIFICE_SIZE = 0.1 ether;
    
    HourglassInterface constant private p3dContract = HourglassInterface(0x0E62d6a4E8354EFC62b1eA7fDFfff2eff0FE5712);
    StrongHandsManagerInterface constant private strongHandsManagerContract = StrongHandsManagerInterface(0x65968E07c824B1acDD2ba913f3EA3b8d9b5f4135);
    StrongHandInterface private strongHandContract;
    
    //not sacrificed players receive their sacrifice amout back + a share of the sacrificed players sacrifice amount 
    uint256 public winningsPerRound = SACRIFICE_SIZE + (SACRIFICE_SIZE / (PLAYERS_PER_ROUND - 1)) / 2;
    
    uint8 public currentPlayers;
    uint256 public round;
    
    uint256 private blocknumber;
    
    mapping(uint8 => address) public slotXplayer;
    
    mapping(address => uint256) private playerVault;
    mapping(address => uint256) private playerRound;
    
    event SacrificeOffered(address indexed player);
    event SacrificeChosen(address indexed sarifice);
    event EarningsWithdrawn(address indexed sarifice, uint256 indexed amount);
    event RoundInvalidated(uint256 indexed round);
    
    constructor()
        public
    {
        //create Strong Hand contract which is used to hold the p3d;
        strongHandsManagerContract.getStrong();
        strongHandContract = StrongHandInterface(strongHandsManagerContract.strongHands(address(this)));
        
        currentPlayers = 0;
        round = 0;
    }
    
    function()
        public
        payable
    {
        acceptSacrifice(msg.value);
    }
    
    function offerSacrifice()
        external
        payable
    {
        acceptSacrifice(msg.value);
    }
    
    function myEarnings()
        external
        view
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function withdraw()
        external
    {
        //players can not withdraw when they participated in current round otherwise they can withdraw funds before sacrifice is chosen
        require(playerRound[msg.sender] < round, "you can not withdraw during a round you are participating in");
        
        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;
        msg.sender.transfer(amount);
        
        emit EarningsWithdrawn(msg.sender, amount);     
    }
    
    function acceptSacrifice(uint256 sacrificeAmount)
        private
    {
        require(sacrificeAmount == SACRIFICE_SIZE, "invalid amount");
        
        //round is already full so determine the winner and start a new round
        if(currentPlayers == PLAYERS_PER_ROUND) {
            //current blocknumber and blocknumber of last player from previous round have to be different
            if(block.number == blocknumber) {
                revert();
            }
            //no sacrifice can be chosen when blocknumber is too old
            if(blockhash(blocknumber) != 0) {
                uint8 sacrificeSlot = uint8(blockhash(blocknumber)) % PLAYERS_PER_ROUND;
                address sacrificePlayer = slotXplayer[sacrificeSlot];
                
                //revert allocated winnigs for sacrifice
                playerVault[sacrificePlayer]-= winningsPerRound;
                
                //allocate p3d dividends to sacrifice
                uint256 dividends = p3dContract.dividendsOf(address(strongHandContract));
                playerVault[sacrificePlayer]+= dividends;
                
                //withdraw dividends
                strongHandContract.withdraw();
                
                //purchase p3d (using ref)
                strongHandContract.buy.value(SACRIFICE_SIZE / 2)(address(0x1EB2acB92624DA2e601EEb77e2508b32E49012ef));
                
                emit SacrificeChosen(sacrificePlayer);
            } else {
                emit RoundInvalidated(round);
            }
            
            //start a new round
            currentPlayers = 0;
            round++;
        }
        
        //save the blocknumber of the last player entering the round, it is used later to determine a random number
        else if(currentPlayers == PLAYERS_PER_ROUND - 1) {
            blocknumber = block.number;
        }
        
        //add the player to the round
        playerRound[msg.sender] = round;
        slotXplayer[currentPlayers] = msg.sender;
        
        //pretend player did not get chosen as sacrifice, will be adjusted for the sacrificed player later
        playerVault[msg.sender]+= winningsPerRound;
        
        currentPlayers++;
        
        emit SacrificeOffered(msg.sender);
    }
}

interface HourglassInterface {
    function dividendsOf(address _customerAddress) view external returns(uint256);
}

interface StrongHandsManagerInterface {
    function getStrong() external;
    function strongHands(address owner) external returns (address);
}

interface StrongHandInterface {
    function buy(address _referrer) external payable;
    function withdraw() external;
}