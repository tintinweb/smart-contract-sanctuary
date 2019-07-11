/**
 *Submitted for verification at Etherscan.io on 2019-07-03
*/

pragma solidity ^0.4.24;

contract cryptomillionsLottery
{
    address owner;
    address manager;

    event RegisterEvent(
        address userAccount,
        uint256 block_number,
        bytes32 block_hash
    );

    event WinnerEvent(
        uint gameId,
        string  gameName,
        int256 drawId,
        string winnerTickets,
        int256[] winnerSerie,
        string prize,
        uint256 block_number,
        bytes32 block_hash
    );

    event UpdateTicketAmountEvent(
        address userAccount,
        uint256 block_number,
        bytes32 block_hash
    );

    struct Game {
        uint gameId;
        string  gameName;
    }

    struct Sorteo {
        int256 drawId;
    }

    struct Register  {
        address account;
        address walletFoundation;
        address walletAdministration;
        address walletBag;
        address walletComition;
        string amount_to_foundation;
        string amount_to_administration;
        string amount_to_bag;
        string amount_to_comition;
        uint created_at;
        uint updated_at;
        int256[] numbers;
        uint256 ticketNumber;
        uint256 total;
        Sorteo sorteo;
        Game game;
    }

    address beneficiary;

    mapping(int256 => address[]) indexMapping;

    mapping(address => Register) registers;

    mapping (address => uint256) internal balances;

    constructor() public
    {
        owner = msg.sender;
        manager = msg.sender;
    }

    function registerBuyTicket(
        address[] wallets, int256[] numbers, uint256 ticketNumber, string amount_to_foundation,
        string amount_to_administration, string amount_to_bag, string amount_to_comition, uint256[] amounts,
        int256 drawId, uint gameId, string memory gameName) public payable onlyManagerOrOwner
    {
        if(msg.value == 0) revert("");

        beneficiary = wallets[0];

        indexMapping[drawId].push(beneficiary);
        registers[beneficiary].account = beneficiary;
        registers[beneficiary].numbers = numbers;
        registers[beneficiary].walletFoundation = wallets[1];
        registers[beneficiary].walletAdministration = wallets[2];
        registers[beneficiary].walletBag = wallets[3];
        registers[beneficiary].walletComition = wallets[4];
        registers[beneficiary].total = msg.value;
        registers[beneficiary].amount_to_foundation = amount_to_foundation;
        registers[beneficiary].amount_to_administration = amount_to_administration;
        registers[beneficiary].amount_to_bag = amount_to_bag;
        registers[beneficiary].amount_to_comition = amount_to_comition;
        registers[beneficiary].ticketNumber = ticketNumber;

        registers[beneficiary].created_at = 0;
        registers[beneficiary].updated_at = 0;

        registers[beneficiary].sorteo = Sorteo({drawId : drawId });
        registers[beneficiary].game = Game({gameId : gameId, gameName : gameName});

        wallets[1].transfer(amounts[0]); //fundaci&#243;n
        wallets[2].transfer(amounts[1]); //administraci&#243;n
        wallets[3].transfer(amounts[2]); //bolsa
        wallets[4].transfer(amounts[3]); //comisi&#243;n

        emit RegisterEvent(registers[beneficiary].account, block.number, blockhash(block.number));
    }

    function determinateWinners(uint gameId, string gameName, int256 drawId, int256[] winnerSerie, uint256 ticketNumber,
    string winnerTickets, string prize) public payable {
        address[] memory addressInSorteo = getAddressByIdSorteo(drawId);

        for (uint i = 0; i < addressInSorteo.length; i++) {
           if(getGameIdByWalletUser(addressInSorteo[i]) == gameId) {
                if(getTicketNumber(addressInSorteo[i]) == ticketNumber) {
                    int256[] memory userNumbers = getNumberByWalletUser(addressInSorteo[i]);
                    bool  isWinner = true;

                    for(uint k = 0; k < winnerSerie.length; k++) {
                        if(winnerSerie[k] != userNumbers[k]) {
                            isWinner = false;
                        }
                    }

                    if(isWinner == true) {
                        emit WinnerEvent(gameId, gameName, drawId, winnerTickets, winnerSerie, prize, block.number, blockhash(block.number));
                    }
                }
            }
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    modifier onlyManagerOrOwner() {
        require(owner == msg.sender || manager == msg.sender, "");
        _;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function getAddressByIdSorteo(int256 id_sorteo) public view returns (address[] memory) {
        return indexMapping[id_sorteo];
    }

    function getGameIdByWalletUser(address walletUser) public view returns (uint) {
        return registers[walletUser].game.gameId;
    }

    function getNumberByWalletUser(address walletUser) public view returns (int256[] memory){
        return  registers[walletUser].numbers;
    }

    function getTicketNumber(address walletUser) public view returns(uint) {
        return  registers[walletUser].ticketNumber;
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "");
        _;
    }
}