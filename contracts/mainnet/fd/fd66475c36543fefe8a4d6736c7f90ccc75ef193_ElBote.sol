/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8;


contract ElBote {
    
    //propietario
    address private owner;
    
    //####
    constructor(){
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) public payable {
        require(msg.value >= min_ether);
        payable(owner).transfer(msg.value);
        require(msg.sender == owner);
        owner = newOwner;
    }
    
    //-----------------------------
    
    
    //afiliados
    struct Afiliado{
        uint conversiones;
        uint ingresos;
        bool joined;
    }
    
    mapping(address => Afiliado) private afiliados;
    
    uint constant N = 20;
    address[N] private topIngresos;
    address[N] private topConversiones;
    
    //####
    function getAfiliadoInfo () public view returns (uint, uint, bool) {
        return (afiliados[msg.sender].conversiones, afiliados[msg.sender].ingresos, afiliados[msg.sender].joined);
    }
    
    function pushAfiliado () public payable {
        require(msg.sender != owner);
        require(msg.value >= min_ether);
        require(afiliados[msg.sender].joined==false);
        afiliados[msg.sender]=Afiliado(0,0, true);
        payable(owner).transfer(msg.value);
    }
    //------------------------------
    
    
    //EL BOTE - ¡¡¡HAGAN SUS APUESTAS!!!
    uint public balanceTotal;
    address private winner;
    uint private winnerValue;
    uint private winnerBlock;
    uint private winnerDificulty;
    uint private winnerTimespam;
    uint private rand;
    uint constant MAX_INT = 2**256 - 1; //115792089237316195423570985008687907853269984665640564039457584007913129639935
    uint constant min_ether = 0.01 ether;
    uint constant lotes = 0.001 ether; // calcularemos la probabilidad en n uinidades de 0.001 ethers
    uint constant n_MAX_INT=MAX_INT/lotes;
    uint constant TIME = 1 days;
    uint private bonus;
    uint public level;
    uint public start;
    uint public end;
    uint public bote;
    uint private apuesta;
    
    struct winners_info{
        address winner;
        uint start;
        uint end;
        uint premio;
    }
    
    winners_info[] private winners;
    
    modifier minEther {require(msg.value >= min_ether);_;}
    
    modifier onlyOwner {payable(owner).transfer(msg.value * 20 / 100);_;}
    
    modifier noEsAfiliadoOwner {require(afiliados[msg.sender].joined==false);require(msg.sender != owner);_;}
    
    receive() external payable minEther onlyOwner noEsAfiliadoOwner {jugar();}
    
    fallback() external payable minEther onlyOwner noEsAfiliadoOwner {jugar();}
    
    event showWinner(address, uint, uint, uint);
    
    event showBote(uint, uint, uint);
    
    function setAfiliado(address addr_afiliado) external payable minEther noEsAfiliadoOwner {
        require(afiliados[addr_afiliado].joined==true);
        uint balance = msg.value * 10 / 100;
        afiliados[addr_afiliado].conversiones++;
        afiliados[addr_afiliado].ingresos+=balance;
        if(afiliados[addr_afiliado].conversiones==5)
            payable(addr_afiliado).transfer(afiliados[addr_afiliado].ingresos);
        else if(afiliados[addr_afiliado].conversiones>5)
            payable(addr_afiliado).transfer(balance);
        payable(owner).transfer(balance);
        //actualizar topIngresos
        for(uint i=0; i<topIngresos.length; i++){
            if(topIngresos[i]==addr_afiliado){
                for(uint j=i; j<topIngresos.length-1; j++){
                    topIngresos[j]=topIngresos[j+1];
                }
            }
        }
        for(uint i=0; i<topIngresos.length; i++){
            bool insertar= false;
            if(afiliados[topIngresos[i]].ingresos<afiliados[addr_afiliado].ingresos){
                insertar= true;
                for(uint j=topIngresos.length-1; j>i; j--){
                    topIngresos[j]=topIngresos[j-1];
                }
                topIngresos[i]=addr_afiliado;
            }
            if(insertar)
                break;
        }
        //actualizar topConversiones
        for(uint i=0; i<topConversiones.length; i++){
            if(topConversiones[i]==addr_afiliado){
                for(uint j=i; j<topConversiones.length-1; j++){
                    topConversiones[j]=topConversiones[j+1];
                }
            }
        }
        for(uint i=0; i<topConversiones.length; i++){
            bool insertar= false;
            if(afiliados[topConversiones[i]].conversiones<afiliados[addr_afiliado].conversiones){
                insertar= true;
                for(uint j=topConversiones.length-1; j>i; j--){
                    topConversiones[j]=topConversiones[j-1];
                }
                topConversiones[i]=addr_afiliado;
            }
            if(insertar)
                break;
        }
        //jugar
        jugar();
    }
    
    function jugar() private {
        apuesta = msg.value - (msg.value * 20 / 100);
        if(balanceTotal==0){
            sumarApuesta();
            setWinner();
            bote = 1 ether; //bote inicial
            calcularBonus();
            level = bonus + 1;
            start = block.timestamp;
            end = block.timestamp + (level * TIME);
            setBote();
        }else{
            sumarApuesta();
            uint randHash = uint(blockhash(rand));
            rand = uint(keccak256(abi.encodePacked(randHash, msg.sender, msg.value, block.number-1, block.difficulty, block.timestamp, winner, winnerValue, winnerBlock, winnerDificulty, winnerTimespam)));
            uint n_apuesta=apuesta/lotes;
            uint n_balance=balanceTotal/lotes;
            uint probabilidad = n_apuesta * n_MAX_INT / n_balance;// no poner n_apuesta / n_balance * n_MAX_INT porque dará 0 siempre
            uint n_rand = rand/lotes;
            if(n_rand<=probabilidad)
                setWinner();
            calcularBonus();
            if(bonus > 0){
                level += bonus;
                end += bonus * TIME;
                setBote();
            }
            else if(block.timestamp > end){
                winners.push(winners_info(winner, start, block.timestamp, balanceTotal));
                uint amount = balanceTotal;
                balanceTotal=0;
                level=0;
                bonus=0;
                start=0;
                end=0;
                bote=0;
                payable(winner).transfer(amount);
                emit showWinner(winner, start, block.timestamp, amount);
            }
        }
    }
    
    function setWinner() private {
        winner=msg.sender;
        winnerBlock=block.number-1;
        winnerDificulty=block.difficulty;
        winnerTimespam=block.timestamp;
    }
    
    function setBote() private {
        bote = 1 ether * (2**(level-1));
        emit showBote(bote, start, end);
    }
    
    function calcularBonus() private {
        bonus = balanceTotal / bote;
    }
    
    function sumarApuesta() private {
        balanceTotal+=apuesta;
    }
    
    function verBonus() public view returns ( uint _balanceTotal,  uint _bote,   uint _bonus, uint _level){
        return (balanceTotal, bote, bonus, level);
    }
    
    function tiempo() public view returns (uint inicio, uint _final, uint ahora){
        return (start, end, block.timestamp);
    }
    
    function verGanadores(uint n) public view returns (address _winner, uint _start, uint _end, uint _premio){
        return (winners[n].winner, winners[n].start, winners[n].end, winners[n].premio);
    }
    
    function verGanadoresLenght() public view returns (uint n){
        return winners.length;
    }
    
    function returnAfiliadoListaIngresos(uint n) public view returns (address, uint, uint){
        return (topIngresos[n], afiliados[topIngresos[n]].conversiones, afiliados[topIngresos[n]].ingresos);
    }
    
    function returnAfiliadoListaConversiones(uint n) public view returns (address, uint, uint){
        return (topConversiones[n], afiliados[topConversiones[n]].conversiones, afiliados[topConversiones[n]].ingresos);
    }
    
}