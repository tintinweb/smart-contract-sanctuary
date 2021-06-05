pragma solidity >=0.5.0 <0.8.0;
// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
import "./FishkaToken.sol";

contract BlackJack {
    struct Player {
        address name; //имя игрока
        uint256 cashAmmount; //колличество денег
        bool hasCards;
        uint32 sumPlayer;
        Card[] cards;
    }
    struct Card {
        string name; //название карты
        uint8 rate; //насколько карта сильна
    }
    struct Dealer {
        address name; //имя дилера
        uint256 cashAmmount; //колличество денег
        uint32 sumDealer; //сумма очков дилера
        Card[] cards;
    }
    FishkaToken token; //экземпляр токена
    Player player;
    Dealer dealer;
    Card[] public deck; //колода карт

    address public winner;
    bool public standP; // сделал ли стэнд игрок
    bool public standD; // сделал ли стэнд дилер

    uint32 constant Cards = 52;
    uint32 ammountOfCards;

    event Deposit(address _from, uint256 _value);
    event Get_Cards(address _from, uint256 sum);
    event Compare(address d, uint256 sumd, address p, uint256 sump);
    modifier points_player() {
        check_cards();
        require(player.sumPlayer <= 21, "You've lost.Total points over 21");
        _;
    } // проверка суммы баллов игрока

    modifier points_dealer() {
        check_cards();
        require(dealer.sumDealer <= 17, "Total points over 17");
        _;
    } // провера суммы баллов дилера
    modifier only_dealer() {
        require(msg.sender == dealer.name, "Only dealer can call this.");
        _;
    }
    modifier only_player() {
        require(msg.sender == player.name, "Only player can call this.");
        _;
    }
    modifier check_balance(uint256 value) {
        require(
            token.balanceOf(msg.sender) >= value,
            "You need more FishkaTokens to play"
        );
        _;
    }

    function get_winner() external view returns (address) {
        return winner;
    }

    function get_stand_dealer() external view returns (bool) {
        return standD;
    }

    function get_stand_player() external view returns (bool) {
        return standP;
    }

    function get_dealer_name() external view returns (address) {
        return dealer.name;
    }

    function get_player_name() external view returns (address) {
        return player.name;
    }

    function get_cards_amount() public view returns (uint count) {
        return ammountOfCards;
    }

    function get_balance_player() public view returns (uint256 cash) {
        return player.cashAmmount;
    }

    function get_balance_dealer() public view returns (uint256 cash) {
        return dealer.cashAmmount;
    }

    function get_player_sum() public view returns (uint32) {
        return player.sumPlayer;
    }

    function get_dealer_sum() public view returns (uint32) {
        return dealer.sumDealer;
    }

    function choose_dealer(uint256 value) public check_balance(value) {
        dealer.cashAmmount = value;

        dealer.name = msg.sender;

        token.transferFrom(dealer.name, address(this), value);
    }

    function choose_player(uint256 value) public check_balance(value) {
        player.cashAmmount = value;
        player.name = msg.sender;
        token.transferFrom(player.name, address(this), value);
    }

    function add_money_player(uint256 value)
        public
        payable
        only_player
    //check_balance(player.cashAmmount + value)
    {
        player.cashAmmount += value;
        token.transferFrom(player.name, address(this), value);
        emit Deposit(msg.sender, value);
    } // увеличение ставки

    function add_money_dealer(uint256 value)
        public
        payable
        only_dealer
    //check_balance(dealer.cashAmmount + value)
    {
        dealer.cashAmmount += value;
        token.transferFrom(dealer.name, address(this), value);
        emit Deposit(msg.sender, value);

        require(
            (player.cashAmmount) == dealer.cashAmmount,
            "Rates must be the same."
        );
    } // увеличение ставки

    function giveToPlayer(uint256 card1, uint256 card2) private {
        player.cards.push(deck[card1]);
        player.sumPlayer += deck[card1].rate;
        deck[card1] = deck[ammountOfCards - 1];
        delete deck[ammountOfCards - 1];
        ammountOfCards--;

        player.cards.push(deck[card2]);
        player.sumPlayer += deck[card2].rate;
        deck[card2] = deck[ammountOfCards - 1];
        delete deck[ammountOfCards - 1];
        ammountOfCards--;
    }

    function giveToPlayer(uint256 card) private {
        Card[] storage card1 = deck;
        player.cards.push(card1[card]);
        player.sumPlayer += deck[card].rate;
        deck[card] = deck[ammountOfCards - 1];
        delete deck[ammountOfCards - 1];
        ammountOfCards--;
    }

    function giveCards() public only_dealer {
        require(!player.hasCards, "The player already has cards.");
        require(deck.length != 0, "No more cards in the deck!");

        //выдача карт
        uint256 card = rand();
        dealer.cards.push(deck[card]);
        dealer.sumDealer += deck[card].rate;
        deck[card] = deck[ammountOfCards - 1];
        delete deck[ammountOfCards - 1];
        ammountOfCards--;

        uint256 card1 = rand();
        uint256 card2 = rand();

        giveToPlayer(card1, card2);

        player.hasCards = true;
        emit Compare(
            dealer.name,
            dealer.sumDealer,
            player.name,
            player.sumPlayer
        );
    } //Раздать карты

    function hit_dealer() public only_dealer points_dealer {
        uint256 cardDealer = rand();
        dealer.cards.push(deck[cardDealer]);
        dealer.sumDealer += deck[cardDealer].rate;
        deck[cardDealer] = deck[ammountOfCards - 1];
        delete deck[ammountOfCards - 1];
        ammountOfCards--;
        emit Get_Cards(dealer.name, dealer.sumDealer);
    } //взять еще одну карту

    function hit_player() public only_player points_player {
        uint256 cardPlayer = rand();
        giveToPlayer(cardPlayer);
        emit Get_Cards(player.name, player.sumPlayer);
    }

    function stand() public {
        if (msg.sender == dealer.name) {
            standD = true;
            token.approve(player.name, dealer.cashAmmount);
        } else {
            standP = true;
            token.approve(dealer.name, player.cashAmmount);
        }
    } // завершить набор карт

    function check_cards() public {
        require(
            player.hasCards,
            "Player doesn't have cards" // у игрока нет карт
        );
        player.sumPlayer = 0;
        dealer.sumDealer = 0;
        for (uint32 i = 0; i < player.cards.length; i++) {
            player.sumPlayer += player.cards[i].rate;
        }
        for (uint32 i = 0; i < dealer.cards.length; i++) {
            dealer.sumDealer += dealer.cards[i].rate;
        }
    } // подсчет суммы баллов

    function checkWinner() public {
        require(
            (player.cashAmmount) == dealer.cashAmmount,
            "Rates must be the same."
        );
        require(standP == true && standD == true, "Not all made 'stand");
        if (
            (player.sumPlayer > dealer.sumDealer) &&
            (player.sumPlayer <= 21) &&
            (dealer.sumDealer <= 21)
        ) {
            token.transfer(
                player.name,
                dealer.cashAmmount + player.cashAmmount
            );
            winner = player.name;
        } else if (player.sumPlayer == dealer.sumDealer) {
            token.transfer(player.name, dealer.cashAmmount);
            token.transfer(dealer.name, player.cashAmmount);
        } else {
            token.transfer(
                dealer.name,
                player.cashAmmount + dealer.cashAmmount
            );
            winner = dealer.name;
        }
        emit Compare(
            dealer.name,
            dealer.sumDealer,
            player.name,
            player.sumPlayer
        );
    }

    function check() public view returns (address) {
        return winner;
    }

    function fillDeck() private {
        ammountOfCards = Cards;
        //в колоде 52 карты, заполняем их
        for (uint8 i = 0; i < 4; i++) {
            //заполняем карты от 2 до 10
            for (uint8 j = 2; j <= 10; j++) {
                deck.push(Card({name: uint2str(j), rate: j}));
            }
            deck.push(
                Card({
                    name: "Jack", //валет
                    rate: 10
                })
            );
            deck.push(
                Card({
                    name: "Lady", //дама
                    rate: 10
                })
            );
            deck.push(
                Card({
                    name: "King", //король
                    rate: 10
                })
            );
            deck.push(
                Card({
                    name: "Ace", //туз
                    rate: 11
                })
            );
        }
    }

    constructor(FishkaToken _token) public {
        token = _token;
        dealer.cashAmmount = 0;
        player.cashAmmount = 0;
        dealer.sumDealer = 0;
        player.sumPlayer = 0;
        fillDeck();
    }

    //Вспомогательные функции
    //Рандом
    uint256 randNonce = 0;

    function rand() internal returns (uint256) {
        randNonce++;
        return
            uint256(keccak256(abi.encodePacked(msg.sender, randNonce))) %
            ammountOfCards;
    }

    function uint2str(uint8 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len = 0;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (true) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
            if (_i != 0) {
                continue;
            } else break;
        }
        return string(bstr);
    }
}