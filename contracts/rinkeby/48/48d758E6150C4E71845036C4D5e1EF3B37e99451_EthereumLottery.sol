/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract EthereumLottery {
    
    // setta owner al deployer del contratto
    constructor() {
        owner = payable(msg.sender);
        lotteryState = State.toStart;
    }
    
    // indirizzo che può chiamare le funzioni onlyOwner
    address moderator;
    
    // setta gli stati in base all'estrazione se è in corso o da iniziare
    enum State {toStart, Started}
    
    // istanza dello stato
    State public lotteryState;
    
    // contatore id delle lotterie
    uint public idLotteryCounter;
    
    // lotterie terminate con vincitori dei premi e data inizio - fine
    struct Lottery {
        address[] terne;
        address[] quaterne;
        address[] cinquine;
        address[] jackpot;
        uint startDate;
        uint endDate;
    }
    
    // storico delle lotterie
    mapping(uint => Lottery) public lotteries;
    
    // range di numeri estraibili
    uint private rangeNumbers = 49;
    
    // indirizzo del wallet proprietario
    address payable private owner;
    
    // indirizzi degli acquirenti
    address payable[] public buyers;
    
    // quantità dei biglietti acquistati dagli acquirenti
    mapping(address => uint) public _quantityTickets;
    
    // numeri dei vari tickets acquistati dagli utenti
    mapping(address => mapping(uint => uint[])) public _tickets;
    
    // numeri vincenti
    uint[] private winningNumbers;

    // nomina il moderatore
    function assignModerator(address _moderator) public onlyOwner {
        moderator = _moderator;
    }
    
    // stato della lotteria
    function checkState() public view returns(State){
        return lotteryState;
    }
    
    // prezzo ipotetico di un terno
    function ternoPrize() public view returns(uint){
        return address(this).balance*10/100/10**16;
    }
    
    // prezzo ipotetico di una quaterna
    function quaternaPrize() public view returns(uint){
        return address(this).balance*15/100/10**16;
    }
    
    // prezzo ipotetico di una cinquina
    function cinquinaPrize() public view returns(uint){
        return address(this).balance*25/100/10**16;
    }
    
    // prezzo ipotetico di un jackpot
    function jackpotPrize() public view returns(uint){
        return address(this).balance*50/100/10**16;
    }
    
    // numeri vincenti
    function getJackpotArray() public view returns (uint[] memory){
        return winningNumbers;
    }
    
    // ticket acquistato in base all'indice
    function getTicketbyIndex(uint index) public view returns (uint[] memory){
        return _tickets[msg.sender][index];
    }
    
    // montepremi totale
    function pool() public view returns(uint){
        return address(this).balance/(10**16);
    }
    
    // balance del wallet proprietario
    function ownerBalance() public view returns(uint){
        return owner.balance;
    }
    
    // modificatore per stabilire da chi le funzioni sono chiamabili
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner or moderator can call this function."
        );
        _;
    }
    
    // modificatore per stabilire da chi le funzioni sono chiamabili
    modifier onlyOwnerOrModerator {
        require(
            msg.sender == owner || msg.sender == moderator,
            "Only owner or moderator can call this function."
        );
        _;
    }
    
    
    // ritorna i vincitori delle terne in base all'id della lotteria
    function getWinnersTerne(uint id) public view returns (address[] memory){
        return lotteries[id].terne;
    }

    // ritorna i vincitori delle quaterne in base all'id della lotteria
    function getWinnersQuaterne(uint id) public view returns (address[] memory){
        return lotteries[id].quaterne;
    }

    // ritorna i vincitori delle cinquine in base all'id della lotteria
    function getWinnersCinquine(uint id) public view returns (address[] memory){
        return lotteries[id].cinquine;
    }

    // ritorna i vincitori delle jackpot in base all'id della lotteria
    function getWinnersJackpot(uint id) public view returns (address[] memory){
        return lotteries[id].jackpot;
    }
    
    // inizia la lotteria impostando la data di inizio
    function startLottery() public onlyOwnerOrModerator {
        lotteryState = State.Started;
        lotteries[idLotteryCounter].startDate = block.timestamp;
    }
    
    // acquisto di uno o più tickets
    function buyTicket(uint quantity) external payable{
        require(checkState() == State.Started, "The lottery has yet to start ");
        require(msg.value == 1 ether * quantity, "Each ticket costs 1 ether!");
        if (_quantityTickets[msg.sender] != 0){
            uint counter;
            for (uint x=0; x<quantity; x++){
                uint[] memory ticket = new uint[](6);
                for (uint y=0; y<6; y++) {
                    ticket[y] = _randModulus(counter++);
                }
                _tickets[msg.sender][x + _quantityTickets[msg.sender]] = ticket;
            }
            _quantityTickets[msg.sender] += quantity;
            owner.transfer(msg.value*10/100);
        } else {
            uint counter;
            for (uint x=0; x<quantity; x++){
                uint[] memory ticket = new uint[](6);
                for (uint y=0; y<6; y++) {
                    ticket[y] = _randModulus(counter++);
                }
                _tickets[msg.sender][x] = ticket;
            }
            _quantityTickets[msg.sender] = quantity;
            buyers.push(payable(msg.sender));
            owner.transfer(msg.value*10/100);
        }
    }
    
    // numeri di tutti i tickets acquistati
    function getTicketsNumbers() public view returns (uint[][] memory){
        uint[][] memory totalTickets = new uint[][](_quantityTickets[msg.sender]);
        for (uint x=0; x<_quantityTickets[msg.sender]; x++){
            totalTickets[x] = _tickets[msg.sender][x];
        }
        return totalTickets;
    }
    
    // calcolo numero randomico
    function _randModulus(uint index) internal view returns (uint){
        return uint(keccak256(abi.encodePacked(
            block.timestamp + index, 
            block.difficulty, 
            owner)
        )) % rangeNumbers;
    }
    
    /* funzione ricorsiva per il check delle vincite (da rivedere)
    
    function checkWin(uint[] memory _winningNumbers, uint[] memory _ticket, uint counter) public pure returns(uint){
        for (uint y=0; y<6; y++){
            if (_ticket[counter] == _winningNumbers[y]){
                counter++;
                checkWin(_winningNumbers, _ticket, counter);
            } 
        }
        return counter;
    }
    
    */
    
    // controllo sull'ipotetica vincita
    function checkWin(uint[] memory _winningNumbers, uint[] memory ticket, uint counter) public pure returns(uint){
            
        for (uint x=0; x<6; x++){
            if (ticket[counter] == _winningNumbers[x]){
                counter++;
                _winningNumbers[x]=60;
                for (uint y=0; y<6; y++){
                    if (ticket[counter] == _winningNumbers[y]){
                        counter++;
                        _winningNumbers[y]=60;
                        for (uint z=0; z<6; z++){
                            if (ticket[counter] == _winningNumbers[z]){
                                counter++;
                                _winningNumbers[z]=60;
                                for (uint q=0; q<6; q++){
                                    if (ticket[counter] == _winningNumbers[q]){
                                        counter++;
                                        _winningNumbers[q]=60;
                                    }   
                                }   
                            } 
                        }
                    }
                }
            }    
        }
        return counter;
    }

    // estrae i numeri vincenti
    function getJackpotNumbers() public onlyOwnerOrModerator {
        for (uint x=0; x<6; x++) {
            winningNumbers.push(_randModulus(x));
        }
    }
    
    // ticket inserito manualmente
    function addManual(uint[] memory manualArr, uint index) public {
        if (_quantityTickets[msg.sender] != 0){
            _tickets[msg.sender][index] = manualArr;
            _quantityTickets[msg.sender] += 1;
        } else {
            _tickets[msg.sender][index] = manualArr;
            buyers.push(payable(msg.sender));
            _quantityTickets[msg.sender] = 1;
        }
    }

    /* sostituisce la prima iterazione della funzione drawn()
    
    function howManyWinnings() internal view returns(uint[] memory){
        uint[] memory quantityWinnings = new uint[](4);
        for (uint x=0; x < buyers.length; x++){ // itera tra tutti gli acquirenti
            for (uint y=0; y < _quantityTickets[buyers[x]]; y++){ // itera per ogni acquirente quanti biglietti ha acquistato
            uint sequence = (checkWin(winningNumbers, _tickets[buyers[x]][y], 0)); // calcola per ogni ticket acquistato dall'acquirente se e cosa ha vinto
                if (sequence == 3) {
                    quantityWinnings[0] += 1;
                } else if (sequence == 4) {
                    quantityWinnings[1] += 1;
                } else if (sequence == 5){
                    quantityWinnings[2] += 1;
                } else if (sequence == 6){
                    quantityWinnings[3] += 1;
                }
            }
        }
        return quantityWinnings;
    }
    
    */
    
    // estrazione con suddivisione premi ipotetici, reset/salvataggio delle variabili e salvataggio data chiusura
    function drawn() public onlyOwnerOrModerator {
        uint terne; // inizializza la variabile per controllare in seguito le terne totali ottenute
        uint quaterne; // inizializza la variabile per controllare in seguito le quaterne totali ottenute
        uint cinquine; // inizializza la variabile per controllare in seguito le cinquine totali ottenute
        uint jackpot; // inizializza la variabile per controllare in seguito i jackpot totali ottenuti
        for (uint x=0; x < buyers.length; x++){ // itera tra tutti gli acquirenti
            for (uint y=0; y < _quantityTickets[buyers[x]]; y++){ // itera per ogni acquirente quanti biglietti ha acquistato
                uint sequence = (checkWin(winningNumbers, _tickets[buyers[x]][y], 0)); // calcola per ogni ticket acquistato dall'acquirente se e cosa ha vinto
                if (sequence == 3) {
                    terne += 1;
                } else if (sequence == 4) {
                    quaterne += 1;
                } else if (sequence == 5){
                    cinquine += 1;
                } else if (sequence == 6){
                    jackpot += 1;
                }
            }
        }
        for (uint x=0; x < buyers.length; x++){ // itera tra tutti gli acquirenti
            for (uint y=0; y < _quantityTickets[buyers[x]]; y++){ // itera per ogni acquirente quanti biglietti ha acquistato
                uint sequence = (checkWin(winningNumbers, _tickets[buyers[x]][y], 0)); // calcola per ogni ticket acquistato dall'acquirente se e cosa ha vinto
                delete _tickets[buyers[x]][y]; // cancella il ticket in quanto già controllato
                if (sequence == 3) {
                    buyers[x].transfer((address(this).balance*10/100)/terne);
                    lotteries[idLotteryCounter].terne.push(buyers[x]);
                } else if (sequence == 4) {
                    buyers[x].transfer((address(this).balance*15/100)/quaterne);
                    lotteries[idLotteryCounter].quaterne.push(buyers[x]);
                } else if (sequence == 5){
                    buyers[x].transfer((address(this).balance*25/100)/cinquine);
                    lotteries[idLotteryCounter].cinquine.push(buyers[x]);
                } else if (sequence == 6){
                    buyers[x].transfer((address(this).balance*50/100)/jackpot);
                    lotteries[idLotteryCounter].jackpot.push(buyers[x]);
                }
            }
            delete _quantityTickets[buyers[x]]; // cancella la quantità di tickets acquistati in quanto già controllati
            delete buyers[x]; // cancella l'acquirente dalla lista in quanto i relativi biglietti sono già stati controllati
        }
        lotteries[idLotteryCounter].endDate = block.timestamp; // imposta data di fine della lotteria
        lotteryState = State.toStart; // imposta stato a toStart
        idLotteryCounter++; // incrementa contatore per la prossima lotteria
    }

}