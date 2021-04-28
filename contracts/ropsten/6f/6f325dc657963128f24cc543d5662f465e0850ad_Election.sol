/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.11;

contract Election {

  // adresse du compte ayant déployé le smart contract
  address public created_by;

  // score des votes: publique tout le monde peut les lire
  int public aScore;
  int public bScore;
  int public counter;

  // structure représentant un votant
  struct Voter {
    // le compte du votant
    address voter_address;
    // l'information précisant qu'il a bien voté
    bool has_voted;
  }

  // tableau permettant de tester si un compte a déjà voté: interne, seul le smart contract a accès a ces données
  mapping(address => Voter) internal voters;

  // évènement émis lors d'un vote
  event newVoteRegistered();

  // constructeur du contrat
  constructor () public {
    // on enregiste le compte ayant déployé le smart contrat
    created_by = msg.sender;
    // initialisation des scores
    aScore = 0;
    bScore = 0;
    counter = 0;
  }

  // Fonction publique permettant de voter pour A
  function voteForA() public {
    // on s'assure que l'utilisateur n'a pas voté
    require(!voters[msg.sender].has_voted, "You've already voted");
    // on incrémente le score de A
    aScore++;
    // on enregistre le votant
    registerVoter(msg.sender);
  }

  // similaire à voteForA mais pour B
  function voteForB() public {
    require(!voters[msg.sender].has_voted, "You've already voted");
    bScore++;
    registerVoter(msg.sender);
  }

  // enregistrement des votes: c'est une fonction interne, elle ne peut que être appelée par le smart contrat lui même
  function registerVoter(address voter) internal {
    // enregistrement du votant
    voters[voter] = Voter({
      voter_address: voter,
      has_voted: true
    });
    counter++;
    // on envoie un évènement précisant qu'un nouveau vote a été enregistré
    emit newVoteRegistered();
  }
}