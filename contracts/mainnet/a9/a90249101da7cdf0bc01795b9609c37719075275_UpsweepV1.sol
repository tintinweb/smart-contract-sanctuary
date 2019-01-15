pragma solidity ^0.5.2;

/*
*
* WELCOME TO THE SUSTAINABLE UPSWEEP NETWORK
*
*                  upsweep.net
*
* Gambling with low gas fees, no edge and no leaks.  
*
*   
*                _19^^^^0^^^^1_
*             .18&#39;&#39;           ``2.
*           .17&#39;      
*          .16&#39;   Here&#39;s to the   `3.
*         .15&#39;      unfolding      `4.
*         ::         of hope.       ::
*         ::  ...................   ::
*         ::                        ::
*         `14.       @author       .5&#39;
*          `13.  symmetricproof   .6&#39;
*           `12.                .7&#39;
*             `11..          ..8&#39;
*                ^10........9^
*                    &#39;&#39;&#39;&#39;     
*
*
/* @title The Upsweep Network; a social and sustainable circle of bets.
*/

contract UpsweepV1 {

    uint public elapsed;
    uint public timeout;
    uint public lastId;
    uint public counter;
    bool public closed;
    
    struct Player {
        bool revealOnce;
        bool claimed;
        bool gotHonour;
        uint8 i;
        bytes32 commit;
    }

    mapping(uint => mapping (address => Player)) public player;
    mapping(uint => uint8[20]) public balancesById;   
    mapping(uint => uint8[20]) public bottleneckById;
    
    address payable public owner = msg.sender;
    uint public ticketPrice = 100000000000000000;
    
    mapping(uint => uint) public honour;
    
    event FirstBlock(uint);
    event LastBlock(uint);
    event Join(uint);
    event Reveal(uint seat, uint indexed gameId);
    event NewId(uint);
    
    modifier onlyBy(address _account)
    {
        require(
            msg.sender == _account,
            "Sender not authorized."
        );
        _;
    }
    
    modifier circleIsPrivate(bool _closed) {
        require(
            _closed == true,
            "Game is in progress."
        );
        _;
    }
    
    modifier circleIsPublic(bool _closed) {
        require(
            _closed == false,
            "Next game has not started."
        );
        _;
    } 
    
    modifier onlyAfter(uint _time) {
        require(
            block.number > _time,
            "Function called too early."
        );
        _;
    }
    
    modifier onlyBefore(uint _time) {
        require(
            block.number <= _time,
            "Function called too late."
        );
        _;
    }
    
    modifier ticketIsAffordable(uint _amount) {
        require(
            msg.value >= _amount,
            "Not enough Ether provided."
        );
        _;
        if (msg.value > _amount)
            msg.sender.transfer(msg.value - _amount);
    }
    
    /**
    * @dev pick a number and cast the hash to the network. 
    * @param _hash is the keccak256 output for the address of the message sender+
    * the number + a passphrase
    */
    function join(bytes32 _hash)
        public
        payable
        circleIsPublic(closed)
        ticketIsAffordable(ticketPrice)
        returns (uint gameId)
    {
        //the circle is only open to 40 players.
        require(
            counter < 40,       
            "Game is full."
        );            
        
        //timer starts when the first ticket of the game is sold
        if (counter == 0) {
            elapsed = block.number;
            emit FirstBlock(block.number);
        }

        player[lastId][msg.sender].commit = _hash;
        
        //when the game is full, timer stops and the countdown to reveal begins
        //NO MORE COMMITS ARE RECEIVED.
        if (counter == 39) {       
            closed = true;
            uint temp = sub(block.number,elapsed);
            timeout = add(temp,block.number);
            emit LastBlock(timeout);
        } 
        
        counter++;

        emit Join(counter);
        return lastId;
    }
   
     /**
    * @notice get a refund and exit the game before it begins
    */
    function abandon()
        public
        circleIsPublic(closed)
        returns (bool success)
    {
        bytes32 commit = player[lastId][msg.sender].commit;
        require(
            commit != 0,
            "Player was not in the game."
        );
        
        player[lastId][msg.sender].commit = 0;
        counter --;
        if (counter == 0) {
            elapsed = 0;
            emit FirstBlock(0);
        }    
        emit Join(counter);
        msg.sender.transfer(ticketPrice);
        return true;
    }     
    /**
    * @notice to make your bet legal, you must reveal the corresponding number
    * @dev a new hash is computed to verify authenticity of the bet
    * @param i is the number (between 0 and 19)
    * @param passphrase to prevent brute-force validation
    */
    function reveal(
        uint8 i, 
        string memory passphrase 
    )
        public 
        circleIsPrivate(closed)
        onlyBefore(timeout)
        returns (bool success)
    {
        bool status = player[lastId][msg.sender].revealOnce;
        require(
            status == false,
            "Player already revealed."
        );
        
        bytes32 commit = player[lastId][msg.sender].commit;
 
        //hash is recalculated to verify authenticity
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender,i,passphrase)
        );
            
        require(
            hash == commit,
            "Hashes don&#39;t match."
        );
        
        player[lastId][msg.sender].revealOnce = true;
        player[lastId][msg.sender].i = i;
        
        //contribution is credited to the chosen number
        balancesById[lastId][i] ++;
        //the list of players inside this numbers grows by one
        bottleneckById[lastId][i] ++;
        
        counter--;
        //last player to reveal must pay extra gas fees to update the game 
        if (counter == 0) {
            timeout = 0;
            updateBalances();
        }
        
        emit Reveal(i,lastId);
        return true;
    }
  
    /**
    * @notice distributes rewards fairly.
    * @dev the circle has no head or foot, node 19 passes to node 0 only if node 0 is not empty.
    * To successfully distribute contributions, the function loops through all numbers and 
    * identifies the first empty number, from there the chain of transfers begins. 
    * 
    */
    function updateBalances()
        public
        circleIsPrivate(closed)
        onlyAfter(timeout)
        returns (bool success)
    {
        // identify the first empty number.
        for (uint8 i = 0; i < 20; i++) {
            if (balancesById[lastId][i] == 0) { 
                // start chain of transfers from the next number.
                uint j = i + 1;
                for (uint8 a = 0; a < 19; a++) {   
                    if (j == 20) j = 0;
                    if (j == 19) {       
                        if (balancesById[lastId][0] > 0) {
                            uint8 temp = balancesById[lastId][19];
                            balancesById[lastId][19] = 0;
                            balancesById[lastId][0] += temp;  
                            j = 0; 
                        } else {
                            j = 1;
                        }
                    } else {            
                        if (balancesById[lastId][j + 1] > 0) { 
                            uint8 temp = balancesById[lastId][j];
                            balancesById[lastId][j] = 0;
                            balancesById[lastId][j + 1] += temp; 
                            j += 1; 
                        } else { 
                            j += 2; 
                        }
                    }
                }
                // will break when all balances are updated.
                break;
            }
        }
        // reset variables and start a new game.
        closed = false;
        if (timeout > 0) timeout = 0;
        elapsed = 0;
        // players that reveal are rewarded the ticket value of those
        // that don&#39;t reveal.
        if (counter > 0) {
            uint total = mul(counter, ticketPrice);
            uint among = sub(40,counter);
            honour[lastId] = div(total,among);
            counter = 0;
        } 
        lastId ++;
        emit NewId(lastId);
        return true;
    }
    
    /**
    * @notice accumulated rewards are already allocated in specific numbers, if players can
    * prove they picked that "lucky" number, they are allowed to withdraw the accumulated
    * ether.
    * 
    * If there is more than one player in a given number, the reward is split equally. 
    * 
    * @param gameId only attempt to withdraw rewards from a valid game, otherwise the transaction
    * will fail.
    */
    function withdraw(uint gameId) 
        public
        returns (bool success)
    {
        bool status = player[gameId][msg.sender].revealOnce;
        require(
            status == true,
            "Player has not revealed."
        );
        
        bool claim = player[gameId][msg.sender].claimed;
        require(
            claim == false,
            "Player already claimed."
        );
        
        uint8 index = player[gameId][msg.sender].i;
        require(
            balancesById[gameId][index] > 0,
            "Player didn&#39;t won."
        );
        
        player[gameId][msg.sender].claimed = true;
        
        uint temp = uint(balancesById[gameId][index]);
        uint among = uint(bottleneckById[gameId][index]);
        uint total = mul(temp, ticketPrice);
        uint payout = div(total, among);
        
        msg.sender.transfer(payout);   
        
        return true;
    }   
    
    function microTip()
        public
        payable
        returns (bool success)
    {
        owner.transfer(msg.value);
        return true;
    }
    
    function changeOwner(address payable _newOwner)
        public
        onlyBy(owner)
        returns (bool success)
    {
        owner = _newOwner;
        return true;
    }
    
    function getHonour(uint _gameId)
        public
        returns (bool success)
    {
        bool status = player[_gameId][msg.sender].gotHonour;
        require(
            status == false,
            "Player already claimed honour."
        );
        bool revealed = player[_gameId][msg.sender].revealOnce;
        require(
            revealed == true,
            "Player has not revealed."
        );
        player[_gameId][msg.sender].gotHonour = true;
        msg.sender.transfer(honour[_gameId]);
        return true;
    }
    
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }


}