/**
* @dev Cryptolotto referral system interface.
*/
contract iCryptolottoReferral {
    /**
    * @dev Get partner by referral.
    */
    function getPartnerByReferral(address) public constant returns (address) {}
    
    /**
    * @dev Get partner percent.
    */
    function getPartnerPercent(address) public view returns (uint8) {}
    
    /**
    * @dev Get sales partner percent by partner address.
    */
    function getSalesPartnerPercent(address) public view returns (uint8) {}
    
    /**
    * @dev Get sales partner address by partner address.
    */
    function getSalesPartner(address) public view returns (address) {}
    
    /**
    * @dev Add new referral.
    */
    function addReferral(address, address) public {}
}

/**
* @dev Cryptolotto stats aggregator interface.
*/
contract iCryptolottoStatsAggregator {
    /**
    * @dev Write info to log about the new winner.
    */
    function newWinner(address, uint, uint, uint, uint8, uint) public {}
}

/**
* @dev Ownable contract interface.
*/
contract iOwnable {
    function getOwner() public view returns (address) {}
    function allowed(address) public view returns (bool) {}
}


/**
* @title Cryptolotto1Day
* @dev This smart contract is a part of Cryptolotto (cryptolotto.cc) product.
*
* @dev Cryptolotto is a blockchain-based, Ethereum powered lottery which gives to users the most 
* @dev transparent and honest chances of winning.
*
* @dev The main idea of Cryptolotto is straightforward: people from all over the world during the 
* @dev set period of time are contributing an equal amount of ETH to one wallet. When a timer ends 
* @dev this smart-contract powered wallet automatically sends all received ETHs to a one randomly 
* @dev chosen wallet-participant.
*
* @dev Due to the fact that Cryptolotto is built on a blockchain technology, it eliminates any 
* @dev potential for intervention by third parties and gives 100% guarantee of an honest game.
* @dev There are no backdoors and no human or computer soft can interfere the process of picking a winner.
*
* @dev If during the game only one player joins it, then the player will receive all his ETH back.
* @dev If a player sends not the exact amount of ETH - he will receive all his ETH back.
* @dev Creators of the product can change the entrance price for the game. If the price is changed 
* @dev then new rules are applied when a new game starts.
*
* @dev The original idea of Cryptolotto belongs to t.me/crypto_god and t.me/crypto_creator - Founders. 
* @dev Cryptolotto smart-contracts are protected by copyright, trademark, patent, trade secret, 
* @dev other intellectual property, proprietary rights laws and other applicable laws.
*
* @dev All information related to the product can be found only on: 
* @dev - cryptolotto.cc
* @dev - github.com/cryptolotto
* @dev - instagram.com/cryptolotto
* @dev - facebook.com/cryptolotto
*
* @dev Cryptolotto was designed and developed by erde group (https://erde.group).
**/
contract Cryptolotto7Days {
    /**
    * @dev Write to log info about the new game.
    *
    * @param _game Game number.
    * @param _time Time when game stated.
    */
    event Game(uint _game, uint indexed _time);

    /**
    * @dev Write to log info about the new game player.
    *
    * @param _address Player wallet address.
    * @param _game Game number in which player buy ticket.
    * @param _number Player number in the game.
    * @param _time Time when player buy ticket.
    */
    event Ticket(
        address indexed _address,
        uint indexed _game,
        uint _number,
        uint _time
    );

    /**
    * @dev Write to log info about partner earnings.
    *
    * @param _partner Partner wallet address.
    * @param _referral Referral wallet address.
    * @param _amount Earning amount.
    * @param _time The time when ether was earned.
    */
    event ToPartner(
        address indexed _partner,
        address _referral,
        uint _amount,
        uint _time
    );

    /**
    * @dev Write to log info about sales partner earnings.
    *
    * @param _salesPartner Sales partner wallet address.
    * @param _partner Partner wallet address.
    * @param _amount Earning amount.
    * @param _time The time when ether was earned.
    */
    event ToSalesPartner(
        address indexed _salesPartner,
        address _partner,
        uint _amount,
        uint _time
    );
    
    // Game type. Each game has own type.
    uint8 public gType = 5;
    // Game fee.
    uint8 public fee = 10;
    // Current game number.
    uint public game;
    // Ticket price.
    uint public ticketPrice = 0.01 ether;
    // New ticket price.
    uint public newPrice;
    // All-time game jackpot.
    uint public allTimeJackpot = 0;
    // All-time game players count
    uint public allTimePlayers = 0;
    
    // Paid to partners.
    uint public paidToPartners = 0;
    // Game status.
    bool public isActive = true;
    // The variable that indicates game status switching.
    bool public toogleStatus = false;
    // The array of all games
    uint[] public games;
    
    // Store game jackpot.
    mapping(uint => uint) jackpot;
    // Store game players.
    mapping(uint => address[]) players;
    
    // Ownable contract
    iOwnable public ownable;
    // Stats aggregator contract.
    iCryptolottoStatsAggregator public stats;
    // Referral system contract.
    iCryptolottoReferral public referralInstance;
    // Funds distributor address.
    address public fundsDistributor;

    /**
    * @dev Check sender address and compare it to an owner.
    */
    modifier onlyOwner() {
        require(ownable.allowed(msg.sender));
        _;
    }

    /**
    * @dev Initialize game.
    * @dev Create ownable and stats aggregator instances, 
    * @dev set funds distributor contract address.
    *
    * @param ownableContract The address of previously deployed ownable contract.
    * @param distributor The address of previously deployed funds distributor contract.
    * @param statsA The address of previously deployed stats aggregator contract.
    * @param referralSystem The address of previously deployed referral system contract.
    */
    function Cryptolotto7Days(
        address ownableContract,
        address distributor,
        address statsA,
        address referralSystem
    ) 
        public
    {
        ownable = iOwnable(ownableContract);
        stats = iCryptolottoStatsAggregator(statsA);
        referralInstance = iCryptolottoReferral(referralSystem);
        fundsDistributor = distributor;
        startGame();
    }

    /**
    * @dev The method that allows buying tickets by directly sending ether to the contract.
    */
    function() public payable {
        buyTicket(address(0));
    }

    /**
    * @dev Returns current game players.
    */
    function getPlayedGamePlayers() 
        public
        view
        returns (uint)
    {
        return getPlayersInGame(game);
    }

    /**
    * @dev Get players by game.
    *
    * @param playedGame Game number.
    */
    function getPlayersInGame(uint playedGame) 
        public 
        view
        returns (uint)
    {
        return players[playedGame].length;
    }

    /**
    * @dev Returns current game jackpot.
    */
    function getPlayedGameJackpot() 
        public 
        view
        returns (uint) 
    {
        return getGameJackpot(game);
    }
    
    /**
    * @dev Get jackpot by game number.
    *
    * @param playedGame The number of the played game.
    */
    function getGameJackpot(uint playedGame) 
        public 
        view 
        returns(uint)
    {
        return jackpot[playedGame];
    }
    
    /**
    * @dev Change game status.
    * @dev If the game is active sets flag for game status changing. Otherwise, change game status.
    */
    function toogleActive() public onlyOwner() {
        if (!isActive) {
            isActive = true;
        } else {
            toogleStatus = !toogleStatus;
        }
    }

    /**
    * @dev Start the new game.`
    */
    function start() public onlyOwner() {
        if (players[game].length > 0) {
            pickTheWinner();
        }
        startGame();
    }

    /**
    * @dev Change ticket price on next game.
    *
    * @param price New ticket price.``
    */    
    function changeTicketPrice(uint price) 
        public 
        onlyOwner() 
    {
        newPrice = price;
    }


    /**
    * @dev Get random number.
    * @dev Random number calculation depends on block timestamp,
    * @dev difficulty, number and hash.
    *
    * @param min Minimal number.
    * @param max Maximum number.
    * @param time Timestamp.
    * @param difficulty Block difficulty.
    * @param number Block number.
    * @param bHash Block hash.
    */
    function randomNumber(
        uint min,
        uint max,
        uint time,
        uint difficulty,
        uint number,
        bytes32 bHash
    ) 
        public 
        pure 
        returns (uint) 
    {
        min ++;
        max ++;

        uint random = uint(keccak256(
            time * 
            difficulty * 
            number *
            uint(bHash)
        ))%10 + 1;
       
        uint result = uint(keccak256(random))%(min+max)-min;
        
        if (result > max) {
            result = max;
        }
        
        if (result < min) {
            result = min;
        }
        
        result--;

        return result;
    }
    
    /**
    * @dev The payable method that accepts ether and adds the player to the game.
    */
    function buyTicket(address partner) public payable {
        require(isActive);
        require(msg.value == ticketPrice);
        
        jackpot[game] += msg.value;
        
        uint playerNumber =  players[game].length;
        players[game].push(msg.sender);

        processReferralSystem(partner, msg.sender);

        emit Ticket(msg.sender, game, playerNumber, now);
    }

    /**
    * @dev Start the new game.
    * @dev Checks ticket price changes, if exists new ticket price the price will be changed.
    * @dev Checks game status changes, if exists request for changing game status game status 
    * @dev will be changed.
    */
    function startGame() internal {
        require(isActive);

        game = block.number;
        if (newPrice != 0) {
            ticketPrice = newPrice;
            newPrice = 0;
        }
        if (toogleStatus) {
            isActive = !isActive;
            toogleStatus = false;
        }
        emit Game(game, now);
    }

    /**
    * @dev Pick the winner.
    * @dev Check game players, depends on player count provides next logic:
    * @dev - if in the game is only one player, by game rules the whole jackpot 
    * @dev without commission returns to him.
    * @dev - if more than one player smart contract randomly selects one player, 
    * @dev calculates commission and after that jackpot transfers to the winner,
    * @dev commision to founders.
    */
    function pickTheWinner() internal {
        uint winner;
        uint toPlayer;
        if (players[game].length == 1) {
            toPlayer = jackpot[game];
            players[game][0].transfer(jackpot[game]);
            winner = 0;
        } else {
            winner = randomNumber(
                0,
                players[game].length - 1,
                block.timestamp,
                block.difficulty,
                block.number,
                blockhash(block.number - 1)
            );
        
            uint distribute = jackpot[game] * fee / 100;
            toPlayer = jackpot[game] - distribute;
            players[game][winner].transfer(toPlayer);

            transferToPartner(players[game][winner]);
            
            distribute -= paidToPartners;
            bool result = address(fundsDistributor).call.gas(30000).value(distribute)();
            if (!result) {
                revert();
            }
        }
    
        paidToPartners = 0;
        stats.newWinner(
            players[game][winner],
            game,
            players[game].length,
            toPlayer,
            gType,
            winner
        );
        
        allTimeJackpot += toPlayer;
        allTimePlayers += players[game].length;
    }

    /**
    * @dev Checks if the player is in referral system.
    * @dev Sending earned ether to partners.
    *
    * @param partner Partner address.
    * @param referral Player address.
    */
    function processReferralSystem(address partner, address referral) 
        internal 
    {
        address partnerRef = referralInstance.getPartnerByReferral(referral);
        if (partner != address(0) || partnerRef != address(0)) {
            if (partnerRef == address(0)) {
                referralInstance.addReferral(partner, referral);
                partnerRef = partner;
            }

            if (players[game].length > 1) {
                transferToPartner(referral);
            }
        }
    }

    /**
    * @dev Sending earned ether to partners.
    *
    * @param referral Player address.
    */
    function transferToPartner(address referral) internal {
        address partner = referralInstance.getPartnerByReferral(referral);
        if (partner != address(0)) {
            uint sum = getPartnerAmount(partner);
            if (sum != 0) {
                partner.transfer(sum);
                paidToPartners += sum;

                emit ToPartner(partner, referral, sum, now);

                transferToSalesPartner(partner);
            }
        }
    }

    /**
    * @dev Sending earned ether to sales partners.
    *
    * @param partner Partner address.
    */
    function transferToSalesPartner(address partner) internal {
        address salesPartner = referralInstance.getSalesPartner(partner);
        if (salesPartner != address(0)) {
            uint sum = getSalesPartnerAmount(partner);
            if (sum != 0) {
                salesPartner.transfer(sum);
                paidToPartners += sum;

                emit ToSalesPartner(salesPartner, partner, sum, now);
            } 
        }
    }

    /**
    * @dev Getting partner percent and calculate earned ether.
    *
    * @param partner Partner address.
    */
    function getPartnerAmount(address partner) 
        internal
        view
        returns (uint) 
    {
        uint8 partnerPercent = referralInstance.getPartnerPercent(partner);
        if (partnerPercent == 0) {
            return 0;
        }

        return calculateReferral(partnerPercent);
    }

    /**
    * @dev Getting sales partner percent and calculate earned ether.
    *
    * @param partner sales partner address.
    */
    function getSalesPartnerAmount(address partner) 
        internal 
        view 
        returns (uint)
    {
        uint8 salesPartnerPercent = referralInstance.getSalesPartnerPercent(partner);
        if (salesPartnerPercent == 0) {
            return 0;
        }

        return calculateReferral(salesPartnerPercent);
    }

    /**
    * @dev Calculate earned ether by partner percent.
    *
    * @param percent Partner percent.
    */
    function calculateReferral(uint8 percent)
        internal 
        view 
        returns (uint) 
    {
        uint distribute =  ticketPrice * fee / 100;

        return distribute * percent / 100;
    }
}