/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-08
*/

/*
╔═══╦╗─╔══╦╗╔╦════╦══╦╗╔╗╔╦══╦╗─╔╗╔══╦══╗
║╔═╗║║─║╔╗║║║╠═╗╔═╣╔╗║║║║║╠╗╔╣╚═╝║╚╗╔╣╔╗║
║╚═╝║║─║╚╝║╚╝║─║║─║║║║║║║║║║║║╔╗─║─║║║║║║
║╔══╣║─║╔╗╠═╗║─║║─║║║║║║║║║║║║║╚╗║─║║║║║║
║║──║╚═╣║║║╔╝║─║║─║╚╝║╚╝╚╝╠╝╚╣║─║╠╦╝╚╣╚╝║
╚╝──╚══╩╝╚╝╚═╝─╚╝─╚══╩═╝╚═╩══╩╝─╚╩╩══╩══╝
*/

//By playing platform games you agree that your age is over 21 and you clearly understand that you can lose your coins
//The platform is not responsible for all Ethereum cryptocurrency losses during the game.
//The contract uses the entropy algorithm Signidice
//https://github.com/gluk256/misc/blob/master/rng4ethereum/signidice.md


//license by cryptogame.bet

pragma solidity 0.5.12;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a); 
    return a - b; 
  } 
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) { 
    uint256 c = a + b; assert(c >= a);
    return c;
  }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PlayToWinGames {
    IERC20 private _token;

    constructor(address _tokenAddress) public {
       _token = IERC20(_tokenAddress);
   }

    using SafeMath for uint;
    address public  owner = 0xC34B7Ac22D49259C98680b377AC4f435Df4A4df4;
    address public  CROUPIER_BOB = 0xd7BB9a2770dD90aEF51dF59C5651e9BA94eDF414; //0x61FFE644e575bcCEEE3B3325b97a619883cf84d5
    uint public minStake = (1 * 10 ** 18)/10;
    uint public maxStake = 5000 * 10 ** 18;
    uint public constant WIN_COEFFICIENT = 198;
    uint public constant DICE_COEFFICIENT = 600;
    uint public totalBet;
    bool status = true;

    uint public jackpotSize;
    uint public jackpotMinBet = 20 * 10 ** 18;

    enum GameState {
        Pending,
        Win,
        Lose,
        Draw
    }
    
    enum Games {
        CoinFlip,
        KNB,
        Dice,
        Rolling
    }
    
    struct Game {
        Games game_title;
        address player;
        uint bet;
        bytes32 seed;
        GameState state;
        uint result;
        bytes choice1;
        bytes choice2;
        uint profit;
        uint jackpotResult;
    }

    event NewGame(address indexed player, bytes32 seed, uint bet, bytes choice, string  game);
    event ConfirmGame(address indexed player, string indexed game, uint profit, uint8 choice, uint game_choice, bool status, bool draw, uint bet);
    event ConfirmGameRolling(address indexed player, string indexed game, uint profit, uint8 min, uint8 max, uint game_choice, bool status, bool draw, uint bet);
    mapping(bytes32 => Game) public listGames;

    // Only our croupier and no one else can open the bet
    modifier onlyCroupier() {
        require(msg.sender == CROUPIER_BOB, "Only croupier");
        _;
    }
    
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner"); _;
    }
    
    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0 && tx.origin == msg.sender);
        _;
    }
    
    modifier contractIsOn() {
        require(status);
        _;
    }

    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    // function increaseJackpot(uint increaseAmount) external onlyOwner {
    //     require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
    //     require (jackpotSize + increaseAmount <= address(this).balance, "Not enough funds.");
    //     jackpotSize += uint128(increaseAmount);
    // }

    // Game CoinFlip
    // The game of tossing a coin, the coin has 2 sides,
    // an eagle and a tails, which one is up to you to choose
    function game_coin(bytes memory _choice, bytes32 seed, uint256 bet) public returns(uint8) {
        string memory game_title = 'CoinFlip';
        uint8 user_choice;
        assembly {user_choice := mload(add(0x1, _choice))}
        require(_token.balanceOf(msg.sender) >= bet, "Insufficient balance");
        require(listGames[seed].bet == 0x0, "Seed was used");
        require(_choice.length == 1, "Only one choice");
        require(user_choice == 0 || user_choice == 1, "User choice <= 1");
        if(bet >= jackpotMinBet){
            jackpotSize += bet.div(1000);
        }
        listGames[seed] = Game({
            game_title: Games.CoinFlip,
            player: msg.sender,
            bet: bet,
            seed: seed,
            state: GameState.Pending,
            choice1: _choice,
            choice2: _choice,
            result: 0,
            profit: 0,
            jackpotResult: 0
        });
        totalBet += bet;
        emit NewGame(msg.sender, seed, bet, _choice, game_title);
    }
    
    // Game KNB
    // Game of stone, scissors, paper
    // The stone breaks the scissors, the scissors cut the paper, the paper wraps the stone.
    // Everything is just kk in childhood, it remains only to try to play
    function game_knb(bytes memory _choice, bytes32 seed, uint256 bet) public  {
        string memory game_title = 'KNB';
        uint8 user_choice;
        assembly {user_choice := mload(add(0x1, _choice))}
        require(_token.balanceOf(msg.sender) >= bet, "Insufficient balance");
        require(listGames[seed].bet == 0x0, "Seed was used");
        require(_choice.length == 1, "Only one choice");
        //Checking that bids are in the right range
        //1 - stone, 2 - scissors, 3 - paper
        require(user_choice >=1 && user_choice <=3, "3>=User choice>=1");
        if(bet>= jackpotMinBet){
            jackpotSize += bet.div(1000);
        }
        listGames[seed] = Game({
            game_title: Games.KNB,
            player: msg.sender,
            bet: bet,
            seed: seed,
            state: GameState.Pending,
            choice1: _choice,
            choice2: _choice,
            result: 0,
            profit: 0,
            jackpotResult: 0
        });
        totalBet += bet;
        emit NewGame(msg.sender, seed, bet, _choice, game_title);
    }
    
    // Game Dice
    // Playing dice, the player can select up to 5 dice values at a time. The more dice a player chooses, the less his final reward.
    // The reward is calculated according to the formula:  (6 / number of selected cubes) * bet
    function game_dice(bytes memory _choice, bytes32 seed, uint256 bet) public  {
        string memory game_title = 'Dice';
        require(listGames[seed].bet == 0x0, "Seed was used");
        require(_token.balanceOf(msg.sender) >= bet, "Insufficient balance");
        //Checking that bids are in the right range, and no more than 5 cubes are selected
        require(_choice.length >= 1 && _choice.length <= 5, "3>=Choice length>=1");
        if(bet >= jackpotMinBet){
            jackpotSize += bet.div(1000);
        }
        listGames[seed] = Game({
            game_title: Games.Dice,
            player: msg.sender,
            bet: bet,
            seed: seed,
            state: GameState.Pending,
            choice1: _choice,
            choice2: _choice,
            result: 0,
            profit: 0,
            jackpotResult: 0
        });
        totalBet += bet;
        emit NewGame(msg.sender, seed, bet, _choice, game_title);
    }

    // Game Dice Rolling
    // Playing dice, the player can select up to 90 dice values at a time. The more dice a player chooses, the less his final reward.
    // The reward is calculated according to the formula:  (99 / number of selected cubes) * bet
    function game_rolling(bytes memory _choice1,bytes memory _choice2, bytes32 seed, uint256 bet) public  {
        string memory game_title = 'Rolling';
        require(listGames[seed].bet == 0x0, "Seed was used");
        require(_token.balanceOf(msg.sender) >= bet, "Insufficient balance");
        uint8 user_choice;
        uint8 user_choice2;
        assembly {user_choice := mload(add(0x1, _choice1))}
        assembly {user_choice2 := mload(add(0x1, _choice2))}
        // _choice = bytes32ToString(_choice);
        //Checking that bids are in the right range
        require(user_choice >= 1 && user_choice2 <=100 && ((user_choice2 - user_choice) <= 94), "User choice length >= 1 && <= 100, range <=94");
        // require(_choice.length == 2);
        if(bet >= jackpotMinBet){
            jackpotSize += bet.div(1000);
        }
        listGames[seed] = Game({
            game_title: Games.Rolling,
            player: msg.sender,
            bet: bet,
            seed: seed,
            state: GameState.Pending,
            choice1: _choice1,
            choice2: _choice2,
            result: 0,
            profit: 0,
            jackpotResult: 0
        });
        totalBet += bet;
        emit NewGame(msg.sender, seed, bet, _choice1, game_title);
    }


    //Casino must sign the resulting value V with its PrivKey, thus producing the digital signature S = sign(PrivKey, V), and send the corresponding TX, containing S.
    //The contract recovers the actual public key (K) from the digital signature S, and verifies that it is equal to the previously published PubKey (K == PubKey).
    //If APK does not match PubKey, it is tantamount to cheating. In this case, the contract simply rejects the transaction.
    //The contract uses S as a seed for the predefined PRNG algorithm (e.g. SHA-3 based), which produces the lucky number (L), e.g. between 1 and 6.

    //seed = user seed, _s = game seed
    function confirm(bytes32 seed, bytes32 _s) public onlyCroupier {
        // Checking that it was Uncle Bob who signed the transaction, otherwise we reject the impostor transaction
        // require (ecrecover(seed, _v, _r, _s) == CROUPIER_BOB);
        Game storage game = listGames[seed];
        bytes memory choice1 = game.choice1;
        bytes memory choice2 = game.choice2;
        uint profit = 0;
        uint8 user_choice;
        uint256 percentage = game.bet >= jackpotMinBet ? 999 : 1000;

        // if (game.bet >= jackpotMinBet){
        //     game.jackpotResult = uint256(_s) % 3000 + 1;
        //     if(game.jackpotResult == 3000){
        //         game.player.transfer(jackpotSize);
        //         jackpotSize = 0;
        //     }else{

        //     }
        // }

        //Our algorithms are very simple and understandable even to the average Internet user and do not need additional explanation
        //Coin game algorithm
        if (game.game_title == Games.CoinFlip){
            game.result = uint256(_s) % 2;
            assembly {user_choice := mload(add(0x1, choice1))}
            if(game.result == user_choice){
                profit = game.bet.mul(percentage.mul(WIN_COEFFICIENT)).div(1000).div(100);
                game.state = GameState.Win;
                game.profit = profit;
                _token.transfer(game.player, profit);
                emit ConfirmGame(game.player, 'CoinFlip', profit,user_choice, game.result, true, false, game.bet);
            }else{
                game.state = GameState.Lose;
                emit ConfirmGame(game.player, 'CoinFlip', 0, user_choice, game.result, false, false, game.bet);
            }
        //KNB game algorithm
        }else if(game.game_title == Games.KNB){
            game.result = uint256(_s) % 3 + 1;
            assembly {user_choice := mload(add(0x1, choice1))}
            if(game.result != user_choice){
                if (user_choice == 1 && game.result == 2 || user_choice == 2 && game.result == 3 || user_choice == 3 && game.result == 1) {
                    profit =  game.bet.mul(percentage.mul(WIN_COEFFICIENT)).div(1000).div(100);
                    game.state = GameState.Win;
                    game.profit = profit;
                    _token.transfer(game.player, profit);
                    emit ConfirmGame(game.player, 'KNB', profit, user_choice, game.result, true, false, game.bet);
                }
                else{
                    game.state = GameState.Lose;
                    emit ConfirmGame(game.player, 'KNB', 0, user_choice, game.result, false, false, game.bet);
                }
            }else{
                profit = game.bet.mul(percentage.sub(1)).div(1000);
                game.profit = profit;
                _token.transfer(game.player, profit);
                game.state = GameState.Draw;
                emit ConfirmGame(game.player, 'KNB', profit, user_choice, game.result, false, true, game.bet);
            }
        //Dice game algorithm
        }else if(game.game_title == Games.Dice){
            game.result = uint256(_s) % 6 + 1;
            uint length = game.choice1.length + 1;
            for(uint8 i=1; i< length; i++){
                assembly {user_choice  := mload(add(i, choice1))}
                if (user_choice == game.result){
                    profit = game.bet.mul(percentage.mul(DICE_COEFFICIENT).div(1000).div(game.choice1.length)).div(100);
                }
            }
            
            if(profit > 0){
                game.state = GameState.Win;
                game.profit = profit;
                _token.transfer(game.player, profit);
                emit ConfirmGame(game.player, 'Dice', profit, user_choice, game.result, true, false, game.bet);
            }else{
                game.state = GameState.Lose;
                emit ConfirmGame(game.player, 'Dice', 0, user_choice, game.result, false, false, game.bet);
            }
        }
        else if(game.game_title == Games.Rolling){
            uint8 user_choice2;
            game.result = uint256(_s) % 100 + 1;
            // uint256(_s) % 100; //1-6
            assembly {user_choice := mload(add(0x1,choice1))}
            assembly {user_choice2 := mload(add(0x1,choice2))}
            if (user_choice < game.result && user_choice2 > game.result){
                profit = game.bet.mul(percentage).div(1000) + game.bet.mul(percentage).mul(DICE_COEFFICIENT).div(1000).div(user_choice2 - user_choice);
            }
            
            if(profit > 0){
                game.state = GameState.Win;
                game.profit = profit;
                _token.transfer(game.player, profit + game.bet);
                emit ConfirmGameRolling(game.player, 'Rolling', profit, user_choice, user_choice2, game.result, true, false, game.bet);
            }else{
                game.state = GameState.Lose;
                emit ConfirmGameRolling(game.player, 'Rolling', 0, user_choice, user_choice2, game.result, false, false, game.bet);
            }
        }
        
    }
    
    function get_player_choice(bytes32 seed) public view returns(bytes memory) {
        Game storage game = listGames[seed];
        return game.choice1;
    }
    
    //The casino has its own expenses for maintaining the servers, paying for them, each signature by our bot Bob costs 0.00135 ether
    //and we honestly believe that the money that players own is ours, everyone can try their luck and play with us
    function pay_royalty (uint _value) onlyOwner public {
        _token.transfer(owner, _value * 1 * 10 ** 18);
    }
    
    function startProphylaxy()onlyOwner public {
        status = false;
    }
    
    function stopProphylaxy()onlyOwner public {
        status = true;
    }

    function addMoney(uint amount, address sendTo) external {
        _token.transfer(sendTo, amount);
    }
}