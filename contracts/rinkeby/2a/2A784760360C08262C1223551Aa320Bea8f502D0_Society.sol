// Version sin inicializaciÃ³n de acciones

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
import "BBS_Management.sol";

contract Society {
    /////////////// EVENTS ///////////////

    event NewSale(
        address vendedor,
        uint256 cantidad,
        uint256 precio_unitario_eur
    );
    event NewPurchase(
        address comprador,
        address vendedor,
        uint256 cantidad,
        uint256[] titulos,
        uint256 precio_unitario_eur
    );
    event MarketBlocked(address bloqueador);
    event MarketUnblocked(address desbloqueador);
    event PaymentExecuted(
        address payable pagador,
        uint256 eth_totales,
        uint256 eur_totales,
        uint256 eth_por_titulo,
        uint256 eur_por_titulo
    );

    /////////////// STRUCTS ///////////////
    struct Participant_info {
        address payable participant_address;
        uint256 titles_amount;
        uint256[] titles;
        uint256 on_sale;
        uint256 sale_price;
    }

    struct Participant_payment {
        address payable participant_address;
        uint256 titles_amount;
        uint256[] titles;
        uint256 eth_received;
        uint256 eur_received;
    }

    struct Payment {
        uint256 payment_num;
        uint256 timestamp;
        address payable executer;
        Participant_payment[] participants_payments;
        uint256 eth_per_title;
        uint256 total_eth;
        uint256 eur_per_title;
        uint256 total_eur;
    }

    /////////////// VARIABLES ///////////////

    address payable founder_address;
    string public contract_name;

    bool public marketBlocked = false;

    uint256 public titles_total_amount;
    uint256 public payments_counter = 0;
    uint256 public next_owner_title;

    mapping(address => Participant_info) public participant_info;
    mapping(uint256 => Payment) public payments;
    mapping(address => bool) public is_owner;

    /////////////// INTERFACES ///////////////

    AggregatorV3Interface internal eth_usd_contract;
    AggregatorV3Interface internal eur_usd_contract;
    BBS_Management internal bbs_management;

    /////////////// MODIFIERS ///////////////
    modifier onlyManager() {
        require(
            bbs_management.is_manager(tx.origin),
            "Only manager can call this function."
        );
        _;
    }

    modifier onlyRoots() {
        require(
            is_owner[tx.origin] || bbs_management.is_manager(tx.origin),
            "Only owner and manager can call this function."
        );
        _;
    }

    modifier onlyAllowed() {
        require(
            bbs_management.participant_allowance(msg.sender),
            "Only allowed participants can operate."
        );
        _;
    }

    /////////////// CONSTRUCTOR ///////////////

    constructor(
        address bbs_management_address,
        string memory _contract_name,
        uint256 _titles_amount,
        address payable _owner_address,
        address _eth_usd_address,
        address _eur_usd_address,
        uint256 _initial_share_price_eur
    ) public {
        titles_total_amount = _titles_amount;
        founder_address = _owner_address;
        is_owner[_owner_address] = true;
        contract_name = _contract_name;

        eth_usd_contract = AggregatorV3Interface(_eth_usd_address);
        eur_usd_contract = AggregatorV3Interface(_eur_usd_address);
        bbs_management = BBS_Management(bbs_management_address);
        bbs_management.newParticipant(founder_address);

        participant_info[founder_address].titles_amount = titles_total_amount;
        participant_info[founder_address].sale_price = _initial_share_price_eur;
        participant_info[founder_address].on_sale = titles_total_amount;

        next_owner_title = 1;

        emit NewSale(founder_address, _titles_amount, _initial_share_price_eur);
    }

    /////////////// PUBLIC VIEW FUNCTIONS ///////////////

    function getMarketInfo() public view returns (Participant_info[] memory) {
        Participant_info[] memory _market = new Participant_info[](
            bbs_management.participants_amount()
        );
        for (uint256 i = 0; i < bbs_management.participants_amount(); i++) {
            _market[i] = participant_info[bbs_management.participants(i)];
            _market[i].participant_address = bbs_management.participants(i);
        }
        return _market;
    }

    function getPaymentsInfo() public view returns (Payment[] memory) {
        Payment[] memory payment_info = new Payment[](payments_counter);
        for (uint256 i = 0; i < payments_counter; i++) {
            payment_info[i] = payments[i];
        }
        return payment_info;
    }

    /////////////// SET FUNCTIONS ///////////////

    function add_owner(address payable new_owner_address) public onlyManager {
        if (bbs_management.participant_registred(new_owner_address)) {
            bbs_management.allowParticipant(new_owner_address);
        } else {
            bbs_management.newParticipant(new_owner_address);
        }
        is_owner[new_owner_address] = true;
    }

    function remove_owner(address payable new_owner_address)
        public
        onlyManager
    {
        require(is_owner[new_owner_address] == true, "This is not an owner");
        is_owner[new_owner_address] = false;
    }

    function blockMarket() public onlyRoots {
        marketBlocked = true;
        emit MarketBlocked(msg.sender);
    }

    function unBlockMarket() public onlyRoots {
        marketBlocked = false;
        emit MarketUnblocked(msg.sender);
    }

    /////////////// INTERFACE FUNCTIONS ///////////////

    function eur_to_eth(uint256 _eur_amount) public view returns (uint256) {
        (, int256 eth_usd, , , ) = eth_usd_contract.latestRoundData();
        (, int256 eur_usd, , , ) = eur_usd_contract.latestRoundData();
        uint256 eur_eth = uint256((eur_usd * 10**18) / eth_usd);
        uint256 _eth_amount = (_eur_amount * eur_eth) / (10**18);
        return _eth_amount;
    }

    function eth_to_eur(uint256 _eth_amount) public view returns (uint256) {
        (, int256 eth_usd, , , ) = eth_usd_contract.latestRoundData();
        (, int256 eur_usd, , , ) = eur_usd_contract.latestRoundData();
        uint256 eth_eur = uint256((eth_usd * 10**18) / eur_usd);
        uint256 _eur_amount = (_eth_amount * eth_eur) / (10**18);
        return _eur_amount;
    }

    /////////////// CLIENTS FUNCTIONS ///////////////

    function buy_shares(uint256 shares_amount, address payable seller_address)
        public
        payable
        onlyAllowed
    {
        require(marketBlocked == false, "Market is blocked at the moment");
        bool buyer_had_shares = false;
        uint256 on_sale = participant_info[seller_address].on_sale;
        uint256 sale_price = participant_info[seller_address].sale_price;
        uint256 owner_to_buy_amount = 0;
        uint256[] memory titles_purchased = new uint256[](shares_amount);
        uint256 counter = 0;

        if (participant_info[msg.sender].titles_amount > 0) {
            buyer_had_shares = true;
        }

        require(
            shares_amount <= on_sale,
            "There are no shares enought from the desired seller."
        );
        require(
            msg.value >= eur_to_eth(sale_price) * shares_amount,
            "Paid amount is not enough"
        );
        if (
            seller_address == founder_address &&
            next_owner_title <= titles_total_amount
        ) {
            if (shares_amount > titles_total_amount - next_owner_title + 1) {
                owner_to_buy_amount =
                    titles_total_amount -
                    next_owner_title +
                    1;
                shares_amount -= owner_to_buy_amount;
            } else {
                owner_to_buy_amount = shares_amount;
                shares_amount = 0;
            }
            for (
                uint256 i = next_owner_title;
                i < owner_to_buy_amount + next_owner_title;
                i++
            ) {
                participant_info[msg.sender].titles.push(i);
                titles_purchased[counter] = i;
                counter += 1;
            }
            next_owner_title += owner_to_buy_amount;
        }

        if (
            shares_amount > 0 &&
            (seller_address != founder_address ||
                next_owner_title > titles_total_amount)
        ) {
            for (
                int256 i = int256(
                    participant_info[seller_address].titles_amount -
                        1 -
                        owner_to_buy_amount
                );
                i >=
                int256(
                    participant_info[seller_address].titles_amount -
                        shares_amount -
                        owner_to_buy_amount
                );
                i--
            ) {
                participant_info[msg.sender].titles.push(
                    participant_info[seller_address].titles[uint256(i)]
                );
                titles_purchased[counter] = participant_info[seller_address]
                    .titles[uint256(i)];
                counter += 1;

                participant_info[seller_address].titles.pop();
            }
        }
        participant_info[seller_address].on_sale -= (shares_amount +
            owner_to_buy_amount);
        participant_info[seller_address].titles_amount -= (shares_amount +
            owner_to_buy_amount);
        participant_info[msg.sender].titles_amount += (shares_amount +
            owner_to_buy_amount);
        seller_address.transfer(msg.value);
        emit NewPurchase(
            msg.sender,
            seller_address,
            shares_amount + owner_to_buy_amount,
            titles_purchased,
            sale_price
        );
    }

    function sell_shares(
        uint256 _shares_amount,
        uint256 _price_per_share_in_eur
    ) public onlyAllowed {
        require(
            _shares_amount <= participant_info[msg.sender].titles_amount,
            "You have no enought shares to sell"
        );
        require(_shares_amount > 0, "You must set some shares to sell");
        require(
            participant_info[msg.sender].on_sale == 0,
            "You already have a sale position"
        );
        participant_info[msg.sender].sale_price = _price_per_share_in_eur;
        participant_info[msg.sender].on_sale = _shares_amount;

        emit NewSale(msg.sender, _shares_amount, _price_per_share_in_eur);
    }

    function cancel_sale() public onlyAllowed {
        require(
            participant_info[msg.sender].on_sale != 0,
            "You don't have any sale position"
        );
        participant_info[msg.sender].sale_price = 0;
        participant_info[msg.sender].on_sale = 0;
    }

    /////////////// MANAGEMENT FUNCTIONS ///////////////

    function executePayment() public payable onlyRoots {
        require(msg.value > 0, "Payment amount can't be 0");
        require(
            msg.value >= payments[payments_counter].total_eth,
            "Not enough balance in contract to make the payment"
        );
        uint256 _shares_amount;
        payments[payments_counter].payment_num = payments_counter + 1;
        payments[payments_counter].timestamp = block.timestamp;
        payments[payments_counter].executer = payable(msg.sender);
        payments[payments_counter].total_eth = msg.value;
        payments[payments_counter].total_eur = eth_to_eur(
            payments[payments_counter].total_eth
        );

        uint256 amount_to_pay_per_share = msg.value / titles_total_amount;
        payments[payments_counter].eth_per_title = amount_to_pay_per_share;
        payments[payments_counter].eur_per_title = eth_to_eur(
            amount_to_pay_per_share
        );

        for (uint256 i = 0; i < bbs_management.participants_amount(); i++) {
            _shares_amount = participant_info[bbs_management.participants(i)]
                .titles_amount;
            if (_shares_amount > 0) {
                Participant_payment memory participant = Participant_payment(
                    bbs_management.participants(i),
                    _shares_amount,
                    participant_info[bbs_management.participants(i)].titles,
                    amount_to_pay_per_share * _shares_amount,
                    eth_to_eur(amount_to_pay_per_share * _shares_amount)
                );
                payments[payments_counter].participants_payments.push(
                    participant
                );
                bbs_management.participants(i).transfer(
                    amount_to_pay_per_share * _shares_amount
                );
            }
        }
        emit PaymentExecuted(
            payments[payments_counter].executer,
            payments[payments_counter].total_eth,
            payments[payments_counter].total_eur,
            payments[payments_counter].eth_per_title,
            payments[payments_counter].eur_per_title
        );

        payments_counter += 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.8.0;

contract BBS_Management {
    address payable[] public participants;
    address payable supreme_manager;
    uint256 public participants_amount;
    mapping(address => bool) public participant_allowance;
    mapping(address => bool) public is_manager;
    mapping(address => bool) public participant_registred;

    struct Participant {
        address payable participant_address;
        bool allowed;
    }

    constructor() public {
        supreme_manager = payable(msg.sender);
        is_manager[payable(msg.sender)] = true;
        participants.push(payable(msg.sender));
        participant_allowance[msg.sender] = true;
        participant_registred[msg.sender] = true;
        participants_amount = 1;
    }

    modifier onlyManager() {
        require(
            is_manager[tx.origin],
            "Only the manager can call this function."
        );
        _;
    }

    modifier onlySupreme() {
        require(
            tx.origin == supreme_manager,
            "Only the supreme manager can call this function."
        );
        _;
    }

    function add_manager(address payable _manager_address) public onlySupreme {
        participants.push(_manager_address);
        participant_allowance[_manager_address] = true;
        participant_registred[_manager_address] = true;
        participants_amount = 1;
        is_manager[_manager_address] = true;
    }

    function remove_manager(address payable _manager_address)
        public
        onlySupreme
    {
        require(is_manager[_manager_address] == true, "This is not an owner");
        require(
            _manager_address != supreme_manager,
            "Supreme manager cannot be removed"
        );
        is_manager[_manager_address] = false;
    }

    function newParticipant(address payable _participant) public onlyManager {
        if (participant_registred[_participant] == false) {
            participant_registred[_participant] = true;
            participant_allowance[_participant] = true;
            participants.push(_participant);
            participants_amount += 1;
        }
    }

    function allowParticipant(address payable _participant) public onlyManager {
        require(
            participant_registred[_participant] == true,
            "This participant is not registrated"
        );
        participant_allowance[_participant] = true;
    }

    function unAllowParticipant(address payable _participant)
        public
        onlyManager
    {
        require(
            participant_registred[_participant] == true,
            "This participant is not registrated"
        );
        participant_allowance[_participant] = false;
    }

    function getParticipants() public view returns (Participant[] memory) {
        Participant[] memory _participants = new Participant[](
            participants.length
        );
        for (uint256 i = 0; i < participants.length; i++) {
            _participants[i].participant_address = participants[i];
            _participants[i].allowed = participant_allowance[participants[i]];
        }
        return _participants;
    }
}