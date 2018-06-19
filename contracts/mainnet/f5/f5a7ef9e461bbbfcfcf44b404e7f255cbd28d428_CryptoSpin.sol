// File: contracts-raw/CryptoSpin.sol

//   ____                  _          ____        _
//  / ___|_ __ _   _ _ __ | |_ ___   / ___| _ __ (_)_ __
// | |   | &#39;__| | | | &#39;_ \| __/ _ \  \___ \| &#39;_ \| | &#39;_ \
// | |___| |  | |_| | |_) | || (_) |  ___) | |_) | | | | |
//  \____|_|   \__, | .__/ \__\___/  |____/| .__/|_|_| |_|
//             |___/|_|                    |_|

// Crypto Spin - Ethereum Slot Machine with Uncompromised RTP
// Copyright 2018 www.cryptospin.co
// In association with www.budapestgame.com

pragma solidity ^0.4.18;

// File: contracts-raw/Ownable.sol

contract Ownable {
        address public        owner;

        event OwnershipTransferred (address indexed prevOwner, address indexed newOwner);

        constructor () public {
                owner       = msg.sender;
        }

        modifier onlyOwner () {
                require (msg.sender == owner);
                _;
        }

        function transferOwnership (address newOwner) public onlyOwner {
              require (newOwner != address (0));

              emit OwnershipTransferred (owner, newOwner);
              owner     = newOwner;
        }
}

// File: contracts-raw/Pausable.sol

contract Pausable is Ownable {
        event Pause ();
        event Unpause ();

        bool public paused        = false;

        modifier whenNotPaused () {
                require(!paused);
                _;
        }

        modifier whenPaused () {
                require (paused);
                _;
        }

        function pause () onlyOwner whenNotPaused public {
                paused  = true;
                emit Pause ();
        }

        function unpause () onlyOwner whenPaused public {
                paused = false;
                emit Unpause ();
        }
}

// File: contracts-raw/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
        function add (uint256 a, uint256 b) internal pure returns (uint256) {
              uint256   c = a + b;
              assert (c >= a);
              return c;
        }

        function sub (uint256 a, uint256 b) internal pure returns (uint256) {
              assert (b <= a);
              return a - b;
        }

        function mul (uint256 a, uint256 b) internal pure returns (uint256) {
                if (a == 0) {
                        return 0;
                }
                uint256 c = a * b;
                assert (c/a == b);
                return c;
        }

        // Solidty automatically throws
        // function div (uint256 a, uint256 b) internal pure returns (uint256) {
        //       // assert(b > 0); // Solidity automatically throws when dividing by 0
        //       uint256   c = a/b;
        //       // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        //       return c;
        // }
}

// File: contracts-raw/CryptoSpin.sol

//   ____                  _          ____        _
//  / ___|_ __ _   _ _ __ | |_ ___   / ___| _ __ (_)_ __
// | |   | &#39;__| | | | &#39;_ \| __/ _ \  \___ \| &#39;_ \| | &#39;_ \
// | |___| |  | |_| | |_) | || (_) |  ___) | |_) | | | | |
//  \____|_|   \__, | .__/ \__\___/  |____/| .__/|_|_| |_|
//             |___/|_|                    |_|

// Crypto Spin - Ethereum Slot Machine with Uncompromised RTP
// Copyright 2018 www.cryptospin.co
// In association with www.budapestgame.com

pragma solidity ^0.4.18;



contract RSPTokenInterface {
        function version () public pure returns (uint8);

        function buyTokens (address referral) public payable;
        function sellTokens (uint256 amount) public;

        function transfer (address to, uint256 amount) public returns (bool);

        // function approve (address spender, uint256 amount) public returns (bool);
        // function transferFrom (address from, address to, uint256 amount) public returns (bool);
}


contract CryptoSpin is Pausable {
        using SafeMath for uint256;

        uint8 public    version             = 2;

        RSPTokenInterface public        rspToken;

        function _setRspTokenAddress (address addr) internal {
                RSPTokenInterface     candidate     = RSPTokenInterface (addr);
                require (candidate.version () >= 7);
                rspToken        = candidate;
        }

        function setRspTokenAddress (address addr) public onlyOwner {
                _setRspTokenAddress (addr);
        }

        // Constructor is not called multiple times, fortunately
        // function CryptoSpin (address addr) public {
        constructor (address addr) public {
                // Onwer should be set up and become msg.sender
                // During test, mint owner some amount
                // During deployment, onwer himself has to buy tokens to be fair
                // _mint (msg.sender, initialAmount);

                if (addr != address(0)) {
                        _setRspTokenAddress (addr);
                }
        }

        event SlotToppedUp (address indexed gamer, uint256 nTokens);
        event SlotToppedDown (address indexed gamer, uint256 nTokens);

        // mapping (address => uint256) public         weisPaid;
        mapping (address => uint256) public         nTokensCredited;
        mapping (address => uint256) public         nTokensWithdrawn;

        // Convenience
        function playerInfo (address player) public view returns (uint256, uint256) {

                return (
                    nTokensCredited[player],
                    nTokensWithdrawn[player]
                );
        }

        // Escrew and start game
        function _markCredit (address player, uint256 nTokens) internal {
                // Overflow check (unnecessarily)
                nTokensCredited[player]     = nTokensCredited[player].add (nTokens);
                emit SlotToppedUp (player, nTokens);
        }

        function _markWithdraw (address player, uint256 nTokens) internal {
                // Overflow check (unnecessarily)
                nTokensWithdrawn[player]    = nTokensWithdrawn[player].add (nTokens);
                emit SlotToppedDown (player, nTokens);
        }

        function buyAndTopup (address referral) whenNotPaused public payable {
                // The contract holds the token until refunding
                rspToken.buyTokens.value (msg.value) (referral);
                uint256     nTokens     = msg.value.mul (8000);

                _markCredit (msg.sender, nTokens);
        }

        function topdownAndCashout (address player, uint256 nTokens) onlyOwner public {
                uint256     nWeis       = nTokens/8000;
                uint256     nRspTokens  = nWeis.mul (5000);

                rspToken.sellTokens (nRspTokens);

                _markWithdraw (player, nTokens);
                player.transfer (nWeis);
        }

        // EndGame
        // function transferTokensTo (address to, uint256 nTokens) onlyOwner public {
        //         rspToken.transfer (to, nTokens);
        // }

        function markCredit (address player, uint256 nTokens) onlyOwner public {
                _markCredit (player, nTokens);
        }

        function () public payable {}


}