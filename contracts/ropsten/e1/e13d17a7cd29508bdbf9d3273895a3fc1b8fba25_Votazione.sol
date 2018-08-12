pragma solidity ^0.4.24;

contract Votazione {
    
    // Elettore &#232; un tipo complesso che rappresenta un elettore
    // (cio&#232; un utente votante) che contiene le variabili 
    // necessarie.
    struct Elettore {        
        bool votato;  // vero = l&#39;elettore ha gi&#224; votato
        uint indice_candidato;   // indice del candidato votato
        bool autorizzato; // vero = avente diritto di voto    
    }


    // Candidato &#232; un tipo complesso che rappresenta un
    // candidato votabile da un elettore 
    struct Candidato {        
        string nome_candidato;   // nome del candidato
        uint conteggio_voti; // numero di voti raccolti    
    }
    
    
    // indirizzo del proprietario del contratto cio&#232;
    // di colui che lo andr&#224; a creare nella blockchain (deploying)
    address public proprietario;


    // associa ad ogni chiave address inserita una relativa
    // struct Elettore
    mapping(address => Elettore) public info_elettore;
    
    // Controllo &#232; un tipo complesso che contiene dati di controllo
    struct Controllo {
        bool votazioni_aperte;
        bool candidati_bloccati;
        bool risultato_visibile;
        int voti_totali;
        int elettori_totali;
        int candidati_totali;
    }
    Controllo public info;

     
    
    // Array (di dimensioni dinamiche) di tipo struct Candidato
    // contenente tutti i candidati richiamati dall&#39;indice
    // (candidati_e_voti &#232; visibile ma inizialmente &#232; vuoto)
    //
    // array_di_candidati verr&#224; copiato in candidati_e_voti alla
    // chiusura delle votazioni, rendendo visibile questo struct
    Candidato[] private array_di_candidati;
    Candidato[] public candidati_e_voti;


    // Costruttore
    constructor() public {
        
        // L&#39;indirizzo pubblico del proprietario del contratto viene
        // qui memorizzato nella variabile proprietario
        proprietario = msg.sender;

        // disabilita la votazione per tutti i votanti
        info.votazioni_aperte = false;


        // sblocca l&#39;inserimento di nuovi candidati
        info.candidati_bloccati = false;

        // nasconde il risultato delle votazioni
        info.risultato_visibile = false;

        // i voti totali inizialmente sono pari a zero
        info.voti_totali = 0;

        // il numero di elettori e di candidati inizialmente &#232; zero
        info.elettori_totali = 0;
        info.candidati_totali = 0;

    }


    
    // Questa funzione crea un nuovo oggetto Candidato 
    // aggiungendolo alla fine dell&#39;array array_di_candidati
    //
    // Ad ogni candidato viene associato un numero di indice
    function aggiungi_candidato (string _candidato) public {

        // La funzione viene terminata se il chiamante
        // non &#232; il proprietario
        require (msg.sender == proprietario);

        // Termina se l&#39;inserimento di nuovi candidati &#232; stato bloccato
        require (!info.candidati_bloccati);
        
        // Viene aggiunto all&#39;array array_di_candidati il nuovo candidato
        // col nome passato dalla funzione.
        // Il candidato avr&#224; inizialmente zero voti
        array_di_candidati.push (   
            Candidato({
                nome_candidato: _candidato,
                conteggio_voti: 0
            }) 
        );
        
        // Aggiorna la variabile pubblica info.candidati_totali prelevandola
        // dal parametro lenght della array privato array_di_candidati
        info.candidati_totali = int256 (array_di_candidati.length);
    }
 
    function avvia_votazioni () public {
       
        // La funzione viene terminata se il chiamante
        // non &#232; il proprietario
        require (msg.sender == proprietario);

        // Termina se le votazioni sono gi&#224; avviate
        require (!info.votazioni_aperte);

        // Termina se le votazioni erano state gi&#224; avviate e chiuse
        // non &#232; possibile riaprire le votazioni una volta chiuse
        // (se candidati_bloccati &#232; true, significa che erano gi&#224;
        // state avviate le votazioni in precedenza)
        require (!info.candidati_bloccati);
 
        // Blocca l&#39;inserimento di nuovi candidati
        info.candidati_bloccati = true;

        // Abilita le votazioni per tutti i votanti
        info.votazioni_aperte = true;
    }

    function chiudi_votazioni () public {

        // La funzione viene terminata se il chiamante
        // non &#232; il proprietario
        require (msg.sender == proprietario);

        // Termina la funzione se le votazioni non erano aperte
        require (info.votazioni_aperte);
 
        // Disabilita le votazioni per tutti i votanti
        info.votazioni_aperte = false; 

        // Rendi visibili i risultati
        info.risultato_visibile = true;

        // Copia il contenuto non visibile dell&#39;array array_di_candidati
        // nell&#39;array pubblico candidati_e_voti
        candidati_e_voti = array_di_candidati;
    }


    // Questa funzione consente di dare il diritto di voto 
    // ad uno specifico indirizzo ethereum
    // Pu&#242; essere chiamata solo dal proprietario
    function assegna_diritto_di_voto (address _elettore) public {
        
        // La funzione viene terminata se l&#39;indirizzo
        // aveva gi&#224; diritto di voto
        require (!info_elettore[_elettore].autorizzato);
        
        // La funzione viene terminata se il chiamante
        // non &#232; il proprietario
        require (msg.sender == proprietario);
        
        // Imposta il diritto di voto per l&#39;indirizzo _elettore
        // settando a vero la variabile autorizzato dell&#39;oggetto
        // elettore
        info_elettore[_elettore].autorizzato = true;
    }
 
 
    // Assegna un voto ad un candidato
    function vota_un_candidato (uint candidato_scelto) public {
     
        // Inserisce in sender un oggetto Elettore preso
        // dall&#39;array "info_elettore" avente indice
        // pari all&#39;indirizzo del chiamante della funzione.
        Elettore storage sender = info_elettore[msg.sender];
        
        // Termina la funzione se le votazioni non sono ancora aperte
        require(info.votazioni_aperte);
        
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

        // Incrementa il conteggio dei voti totali
        info.voti_totali += 1;
    } 
 
    
    // Restituisce il numero di indice del vincitore
    // "view" significa che non pu&#242; modificare lo stato di nessuna variabile
    function indice_vincitore () public view returns (uint indice) {

        // Termina la funzione se il risultato deve restare nascosto
        require (info.risultato_visibile);

        // Scorre i voti di tutti i candidati e sovrascrive "voto_temporaneo"
        // se il relativo conteggio risultasse maggiore del precedente ciclo
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
    function nome_vincitore () public view returns (string n)
    {
        // Termina la funzione se il risultato deve restare nascosto
        require (info.risultato_visibile);

        // estrae il nome dall&#39;oggetto array_di_candidati
        n = array_di_candidati[indice_vincitore()].nome_candidato;
    }

    // Restituisce il nome del candidato inserendo l&#39;indice (getter)
    function nome_candidato_da_indice (uint i) public view returns (string nomecand) {
        // Se l&#39;indice passato alla funzione &#232; tra quelli presenti in memoria
        if (i<array_di_candidati.length){
            nomecand = array_di_candidati[i].nome_candidato;
        // Se l&#39;indice passato &#232; troppo grande
        } else {
            nomecand = "Nessun candidato in questo indice!";
        }
    }


    
}