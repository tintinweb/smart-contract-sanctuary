pragma solidity ^ 0.4 .22;
contract Smartgrid {

    // =================
    // State Machine
    // =================
    enum Stages {
        Initialisation,
        cycleDeVie
    }
    Stages public stage = Stages.Initialisation;

    // =================
    // Public Variables
    // =================
    mapping(address => uint) public producteurList;
    address public owner;
    uint public index;
    contrat[] public contratList;
    mapping(address => uint) public energieTokenList;

    // =================
    // Actors whiteList address
    // =================


    // =================
    // Events declaration
    // =================


    // =================
    // Structs declaration
    // =================
    struct contrat {
        address[] utilisateurs;
        uint[] pourcentages;
        address producteur;
    }

    // =================
    // Transitions
    // =================
    function from_Initialisation_to_cycleDeVie() atStage(Stages.Initialisation) public {
        if (true) {
            stage = Stages.cycleDeVie;
        }
    }

    // =================
    // Transactions
    // =================
    constructor() atStage(Stages.Initialisation) public { /* Check variables values */

        /* Add implementation behavior here */
        owner = msg.sender;

        /* Send money, event, etc. here */


        from_Initialisation_to_cycleDeVie();
    }

    function nouvelleProduction(uint amount) atStage(Stages.cycleDeVie) public {
        address user;
        uint newbalance;
        uint pourcentage;
        uint indexUser;
        uint id;
        uint nbutilisateur;
        /* Check variables values */
        id = producteurList[msg.sender];
        if (id == 0) {
            revert();
        }
        nbutilisateur = contratList[id].utilisateurs.length;

        /* Add implementation behavior here */
        uint indexUser_inc = 1;
        for (indexUser = 0; indexUser < nbutilisateur; indexUser += indexUser_inc) {
            pourcentage = contratList[id].pourcentages[(indexUser - 1)];
            user = contratList[id].utilisateurs[(indexUser - 1)];
            newbalance = amount / pourcentage + energieTokenList[user];
            energieTokenList[user] = newbalance;
        }

        /* Send money, event, etc. here */


    }

    function retribution(uint amount, address beneficiary) atStage(Stages.cycleDeVie) public { /* Check variables values */
        if (amount > energieTokenList[msg.sender]) {
            revert();
        }

        /* Add implementation behavior here */
        energieTokenList[owner] = (energieTokenList[owner] + amount);
        energieTokenList[msg.sender] = (energieTokenList[msg.sender] - amount);

        /* Send money, event, etc. here */


    }

    function nouveauContrat(address producteur, address[] _utilisateurs, uint[] _pourcentages) atStage(Stages.cycleDeVie) public {
        uint temp;
        /* Check variables values */
        if (msg.sender != owner) {
            revert();
        }

        /* Add implementation behavior here */
        contratList.push(contrat({
            utilisateurs: _utilisateurs,
            pourcentages: _pourcentages,
            producteur: producteur
        }));
        producteurList[producteur] = index;

        /* Send money, event, etc. here */
        index = (index + 1);


    }

    // =================
    // State Machine Modifier
    // =================
    modifier atStage(Stages _expectedStage) {
        if (stage == _expectedStage) {
            _;
        }
    }

    // =================
    // Restricting Access by actor Modifier
    // =================


    // =================
    // Utils functions for structs
    // =================
    function findIndexWherecontratProperty(contrat[] structArray, bytes32 structProperty, bytes4 operator, bytes32 value) internal pure returns(uint) {
        uint index = 0;

        return index;
    }

    function findStructWherecontratProperty(contrat[] structArray, bytes32 structProperty, bytes4 operator, bytes32 value) internal pure returns(contrat) {
        contrat memory item = structArray[0];

        return item;
    }
}