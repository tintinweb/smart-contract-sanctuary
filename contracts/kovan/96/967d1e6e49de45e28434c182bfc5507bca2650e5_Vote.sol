// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Vote is Ownable {

    // La question et ses choix possibles
    string public question;
    mapping(uint => string) public answerChoices;
    uint public nbAnswerChoices;

    // Liste des réponses
    mapping(address => Response) public responses;
    mapping(uint => address) public listResponces;
    uint public nbResponse;

    // Etat d'ouverture / fermeture du vote
    bool public isActive;

    constructor() {
        nbResponse = 0;
        nbAnswerChoices = 0;
        isActive = false;
    }

    // Structure de réponse
    struct Response {
        uint choice;
        bool active;

    }

    // Modifier l'état d'ouverture des votes
    function setIsActive(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    // Modifier la question
    function setQuestion(string memory _question) external onlyOwner notResponses isNotActived {
        question = _question;
    }

    // Ajouter un choix
    function addAnswerChoice(string memory _answerChoice) external onlyOwner notResponses isNotActived {
        answerChoices[nbAnswerChoices] = _answerChoice;
        nbAnswerChoices++;
    }

    // Supprimer un choix
    function deleteAnswerChoice(uint _index) external onlyOwner notResponses isNotActived {
        for (uint i = _index; i < nbAnswerChoices; i++) {
            answerChoices[i] = answerChoices[i + 1];
        }
        delete answerChoices[nbAnswerChoices - 1];
        nbAnswerChoices--;
    }

    // Condition : il ne doit pas y avoir de réponse
    modifier notResponses(){
        require(nbResponse == 0);
        _;
    }

    // Condition : Le vote ne deoit pas être ouvert / activé
    modifier isNotActived() {

        require(isActive == false, "This Vote Contract is actived. You can't changed this contract !");
        _;
    }

    // Condition : Ne doit pas avoir déjà voté
    modifier isNotVoted() {

        address currentUser = msg.sender;
        Response memory response = responses[msg.sender];

        require(response.active == false, "You have already voted !");
        _;
    }

    // Voter
    function addAnswer(uint _value) external isNotVoted {

        require(_value < nbAnswerChoices, "Incorrect value !");

        address currentUser = msg.sender;
        responses[currentUser] = Response(_value, true);
        listResponces[nbResponse] = currentUser;
        nbResponse++;
    }

    // Renvoie "true" si l'address en paramètre à déjà voté.
    function userVoted(address _voter) public view returns (bool){

        Response memory response = responses[_voter];
        return response.active;
    }
}