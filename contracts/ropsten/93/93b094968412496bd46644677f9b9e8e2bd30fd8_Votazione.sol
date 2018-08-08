pragma solidity ^0.4.24;

contract Votazione {
    
    // Elettore &#232; un tipo complesso che rappresenta un elettore
    // (cio&#232; un utente votante) che contiene le variabili 
    // necessarie.
    struct Elettore {        
        bool votato;  // vero = l&#39;elettore ha votato
        uint indice_candidato;   // indice del candidato votato
        bool autorizzato; // vero = avente diritto di voto    
    }


    // Candidato &#232; un tipo complesso che rappresenta un
    // candidato votabile da un elettore 
    struct Candidato {        
        bytes32 nome_candidato;   // nome del candidato (fino a 32 bytes)
        uint conteggio_voti; // numero di voti raccolti    
    }
    
    
    // indirizzo del proprietario del contratto cio&#232;
    // di colui che lo andr&#224; a creare nella blockchain (deploying)
    address public proprietario;


    // associa ad ogni chiave address inserita una relativa
    // struct Elettore
    mapping(address => Elettore) public elettore_da_indirizzo;
    
    
    // Array (di dimensioni dinamiche) di tipo struct Candidato
    // contenente tutti i candidati richiamati dall&#39;indice
    // (si potrebbe rendere privato per non rendere palese il risultato
    // parziale dei voti che pu&#242; influenzare i voti restanti)
    Candidato[] public array_di_candidati;


    // Creazione di uno scrutinio con la lista dei candidati da votare.
    constructor(bytes32[] nomi_candidati) public {
        
        // L&#39;indirizzo pubblico del creatore del contratto viene
        // qui memorizzato nella variabile proprietario
        proprietario = msg.sender;
        
        
        // Per ogni nome di candidato fornito nel costruttore
        // viene creato un nuovo oggetto Candidato e viene
        // aggiunto alla fine dell&#39;array_di_candidati
        // Ad ogni candidato viene associato un numero di indice
        for (uint a = 0; a < nomi_candidati.length; a++) {
            
            // L&#39;array_di_candidati conterr&#224; i nomi passati
            // nel costruttore, e ciascuno avr&#224; inizialmente
            // zero voti
            array_di_candidati.push (
            Candidato({
                nome_candidato: nomi_candidati[a],
                conteggio_voti: 0
                }) 
            );
        }
    }
 

    // Questa funzione consente di dare il diritto di voto 
    // ad uno specifico indirizzo ethereum
    // Pu&#242; essere chiamata solo dal proprietario
    function assegna_diritto_di_voto(address _elettore) public {
        
        // La funzione viene terminata se l&#39;indirizzo
        // aveva gi&#224; diritto di voto
        require (!elettore_da_indirizzo[_elettore].autorizzato);
        
        // La funzione viene terminata se il chiamante
        // non &#232; il proprietario
        require (msg.sender == proprietario);
        
        // Imposta il diritto di voto per l&#39;indirizzo
        // settando a vero la variabile autorizzato dell&#39;oggetto
        // elettore
        elettore_da_indirizzo[_elettore].autorizzato = true;
    }
 
 
    // assegna un voto ad un candidato
    function vota_un_candidato(uint candidato_scelto) public {
     
        // Inserisce in sender un oggetto Elettore preso
        // dall&#39;array "elettore_da_indirizzo" avente indice
        // pari all&#39;indirizzo del chiamante della funzione
        // "storage" imposta forzatamente che i valori devono
        // essere archiviati permanentemente e non memorizzati
        // in modo volatile
        Elettore storage sender = elettore_da_indirizzo[msg.sender];
        
        // Termina la funzione se il votante ha gi&#224; votato
        require(!sender.votato);
        
        // Termina se il votante non &#232; autorizzato
        require(sender.autorizzato);
       
        // Imposta che questo elettore ha votato 
        // (non potr&#224; votare di nuovo)
        sender.votato = true;
        
        // Imposta l&#39;indice del candidato dell&#39;oggetto Elettore
        // (omettere per rendere il voto anonimo)
        sender.indice_candidato = candidato_scelto;

        // Incrementa il numero di voti per il candidato con indice
        //"candidato scelto"
        array_di_candidati[candidato_scelto].conteggio_voti += 1;
    } 
 
    
    // Restituisce il numero di indice del indice
    // "view" significa che non pu&#242; modificare lo stato di nessuna variabile
    function indice_vincitore() public view returns (uint indice) 
    {
        // scorre i voti di tutti i candidati e sovrascrive "voto_temporaneo"
        // se il relativo conteggio risulta maggiore del precedente ad ogni ciclo
        uint voto_temporaneo = 0;
        for (uint p = 0; p < array_di_candidati.length; p++) {
            if (array_di_candidati[p].conteggio_voti > voto_temporaneo) {
                voto_temporaneo = array_di_candidati[p].conteggio_voti;
                indice = p;
            }
        }
    }


    // Usa la funzione "indice_vincitore" per restituire il nome contenuto
    // nell&#39;"array_di_candidati" (identificandolo con l&#39;indice del vincitore)
    function Nome_vincitore() public view returns (bytes32 n)
    {
        n = array_di_candidati[indice_vincitore()].nome_candidato;
    }

    // Restituisce il nome del candidato inserendo l&#39;indice (getter)
    function nome_candidato_da_indice (uint i) public view returns (bytes32 nomecand) {
        nomecand = array_di_candidati[i].nome_candidato;
    }


    
}