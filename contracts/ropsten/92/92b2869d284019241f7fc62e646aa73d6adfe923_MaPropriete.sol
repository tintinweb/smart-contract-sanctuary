/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.6.4;


contract MaPropriete {

    // Différents états d'une propriété
    enum EtatPropriete { EN_VENTE, EN_PASSATION, ALIENE }

    struct Propriete {
        uint256 id;
        address payable proprietaire; // Propriétaire
        uint256 lat; // Latitude
        uint256 long; // Longitude
        uint256 prix; // Prix en wei
        EtatPropriete etat; // Etat de la propriété
    }

    event Vente(uint256 id, address ancienProprio, address nouveauProprio);
    event MiseEnVente(uint256 id, uint256 prix, uint256 date);

    // Liste dynamique des propriétés
    uint256[] private listProprietes;

    // Liste des propriétés indexée par une valeur numérique
    mapping(uint256 => Propriete) public proprietes;

    mapping(address => bool) agents;

    // Fonctions uniquement utilisables par un agent agréé
    modifier estAgentAgree() {
        require(agents[msg.sender], "Doit être un agent agréé");
        _;
    }
    // Fonctions uniquement utilisables par le propriétaire de la propriété donnée
    modifier estProprietaire(uint256 _id) {
        require(proprietes[_id].proprietaire == msg.sender, "Doit être propriétaire");
        _;
    }

    constructor() public {
        agents[msg.sender] = true;
    }

    function ajouterAgentAgree(address _agent) estAgentAgree external {
        require(_agent != address(0x0), "L'adresse ne doit pas être égale à 0");
        agents[_agent] = true;
    }

    function retirerAgentAgree(address _agent) estAgentAgree external {
        agents[_agent] = false;
    }

    // Achat d'une propriété
    function acheterPropriete(uint256 _id)
        external
        payable
    {
        Propriete memory propriete = proprietes[_id];

        // Protège des montants à 0
        require(msg.value > 0, "Le montant ne peut être de 0");
        // La propriété doit être en vente
        require(propriete.etat == EtatPropriete.EN_VENTE, "La propriété doit être en vente");
        // Le montant doit être exact
        require(msg.value == propriete.prix, "Montant insuffisant ou trop élevé");
        propriete.proprietaire.transfer(msg.value);

        emit Vente(_id, propriete.proprietaire, msg.sender);

        changerProprietaire(_id, msg.sender);
    }

    function ajouterPropriete(
        address payable _proprietaire,
        uint256 _id,
        uint256 _lat,
        uint256 _long
    ) external estAgentAgree {
        // Interdiction de mettre l'identifiant à 0
        require(_id > 0, "Identifiant de la propriété 0 impossible");
        // L'identifiant ne doit pas exister déjà
        require(proprietes[_id].proprietaire == address(0x0), "Identifiant déjà utilisé");
        // Prix par défaut à 0. L'achat de la propriété ne peut se faire quand un montant est à 0
        proprietes[_id] = Propriete(_id, _proprietaire, _lat, _long, 0, EtatPropriete.ALIENE);
        // On conserve une liste dynamique des propriétés recensées
        listProprietes.push(_id);
    }

    // Passe la propriété à un nouveau proprétaire. Cette fonction est privée est n'est utilisée que lorsque un
    // propriété est vendue
    function changerProprietaire(uint256 _id, address payable _nouveauProprietaire) private {
        require(proprietes[_id].proprietaire != address(0x0), "Propriété inexistante");
        proprietes[_id].proprietaire = _nouveauProprietaire;
        proprietes[_id].etat = EtatPropriete.EN_PASSATION;
    }

    function declarerPropriete(uint256 _id) external estProprietaire(_id) {
        require(proprietes[_id].etat == EtatPropriete.EN_PASSATION, "Doit être en passation");
        proprietes[_id].etat = EtatPropriete.ALIENE;
    }

    function mettreProprieteEnVente(uint256 _id, uint256 _prix) external estProprietaire(_id) {
        // Donation de la propriété impossible
        require(_prix > 0, "Le prix de vente ne peut pas être de 0");

        proprietes[_id].prix = _prix;
        proprietes[_id].etat = EtatPropriete.EN_VENTE;

        // Journalisation de la mise en vente avec la date du moment d'exécution de la fonction (now)
        emit MiseEnVente(_id, _prix, now);
    }

    function proprieteEstEnVente(uint256 _id) public view returns(bool) {
        return proprietes[_id].etat == EtatPropriete.EN_VENTE;
    }

    // Trouver un propriété en fonction de sa latitude et sa longitude
    function trouverPropriete(uint256 _lat, uint256 _long) external view returns(uint256) {
        // Parcourt de la liste des propriétés recensés
        for (uint256 i; i < listProprietes.length; i++) {
            uint256 id = listProprietes[i];
            // Si la bonne latitude et longitude est trouvée on retourne l'identifiant de la propriété
            if (proprietes[id].lat == _lat && proprietes[id].long == _long) {
                return id;
            }
        }

        // Par défaut on retourne la propriété d'identifiant 0
        return 0;
    }

    // Trouve les propriétés dans une localisation donnée
    // et retourne les identifiants
    function localiserProprietes(
        uint256 _latA, uint256 _latB,
        uint256 _longA, uint256 _longB
    ) external view returns (uint256[] memory props) {
        uint256 index = 0;
        for (uint256 i; i < listProprietes.length; i++) {
            uint256 id = listProprietes[i];
            if (
                (proprietes[id].lat >= _latA && proprietes[id].lat <= _latB) &&
                (proprietes[id].long >= _longA && proprietes[id].long <= _longB)
            ) {
                props[index] = id;
                index++;
            }
        }
    }


    function totalProprietes() external view returns (uint256) {
        return listProprietes.length;
    }
}