/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vote {

    int choice;
    address owner;

	// Objet Vote ****************************************
    struct Voter {
        bool voted;    // if true, that person already voted
        uint choice;   // index of the voted proposal
    }

	// tous les get et pour voter
    struct reacVote {
		uint indexCategorie;
		uint indexQuestionnaire;
		uint indexQuestion;
		address sender;
        uint choice;
    }

	// Objet Question ****************************************
    struct structQuestion {
		bool isexist;
        bool deleted;    // if true, ne plus afficher la question
		string titre;
		string question;
		string[] reponses;
		// TODO : int image sur ipfs;
		//mapping(address => Voter) votants;
    	//address[] votantsIndex;
    	bytes32[] votants;
		// compteurs pour l'interface mais pas sur que cela soit une bonne idée
		uint counter;
		uint[] counterReponses;
    }

    struct reacQuestion {
		string titre;
		string question;
		string[] reponses;
    }

	// Objet Questionnaire ****************************************
    struct structQuestionnaire {
    	address	owner;
		bool isexist;
        bool close;    // if true, questionnaire terminé
        bool deleted;    // if true, ne plus afficher le questionnaire
		string name;
		//mapping (uint => structQuestion) questions;
    	//uint[] questionsIndex; // for listQuestions
		//structQuestion[] questions;
		bytes32[] questions;
	}

	// structure reacQuestionnaire
    struct reacQuestionnaire {
		uint indexCategorie;
		uint index;
		string name;
		uint questions; // number of questions in questionnaire
    }

	// Objet Categories ****************************************
    struct structCategories {
    	address	owner;
		bool isexist;
        bool deleted;    // if true, ne plus afficher la categorie
		string name;
		//mapping (uint => structQuestionnaire) questionnaires;
    	//uint[] questionnairesIndex;
		//structQuestionnaire[] questionnaires;
    	bytes32[] questionnairesIndex;
	}

	// structure reacCategories
    struct reacCategories {
		uint index;
        bool deleted;    // if true, ne plus afficher la categorie
		string name;
		uint questionnaires; // number of questionnaires in categorie
    }

	//mapping (uint => structCategories) categories;
    //uint[] categoriesIndex;
	structCategories[] categories;

	// Modifiers ***********************************************
	/*
	modifier noOwner(address owner) {
		require(owner == msg.sender, "not owner !");
		_;
	}
	modifier noOwnerCategorie(uint _categorie) {
		require(categories[_categorie].owner == msg.sender, "not owner of this categorie !");
		_;
	}
	modifier noExistCategorie(uint _categorie) {
		require(_categorie < categories.length, "Categorie not exist !");
		_;
	}
	modifier noExistQuestionnaire(uint _categorie, uint _questionnaire) {
		require(_categorie < categories.length, "Categorie not exist !");
		require(_questionnaire < categories[_categorie].questionnaires.length, "questionnaire not exist !");
		//require(categories[_categorie].questionnaires[_questionnaire].isexist, "questionnaire not exist !");
		_;
	}
	modifier noExistQuestion(uint _categorie, uint _questionnaire, uint _question) {
		require(_categorie < categories.length, "Categorie not exist !");
		require(_questionnaire < categories[_categorie].questionnaires.length, "questionnaire not exist !");
		require(_question < categories[_categorie].questionnaires[_questionnaire].questions.length, "question not exist !");
		//require(categories[_categorie].questionnaires[_questionnaire].questions[_question].isexist, "question not exist !");
		_;
	}
	*/

	// Fonctions ***********************************************
    constructor() {
        owner = msg.sender;
        choice = -1;
    }

    function uuId(string memory addedParam) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32(block.timestamp),bytes(addedParam)));
    }

	// ***********************************************************
	// fonctions Vote *** ****************************************
	// ***********************************************************
/*
	// From interface web ****************************
    function addVote(structQuestion storage _memoryQuestion, address _sender, int _value) internal returns (bool) {
        // TODO : add keccak256() to sender ?
		_memoryQuestion.votants[_sender].voted = true;
		_memoryQuestion.votants[_sender].choice = uint(_value);
		_memoryQuestion.votantsIndex.push(_sender);
		return true;
	}		

	// For interface web ****************************
    function isVoted(structQuestion storage _memoryQuestion, address _sender) internal view returns (bool) {
        // TODO : add keccak256() to sender ?
        return (_memoryQuestion.votants[_sender].voted);
    }
*/

	// ***********************************************************
	// fonctions Question ****************************************
	// ***********************************************************
/*
	// For interface web ****************************
	// return question result (for interface web)
    function getResultsVote(structQuestion storage _memoryQuestion) internal view returns (uint[] memory) {
		uint[] memory resultsQuestion;
		resultsQuestion[0] = _memoryQuestion.counter;
		// Boucle sur liste des resultats de la question par reponses
		for (uint i = 0; i < _memoryQuestion.reponses.length; i++) {
		    resultsQuestion[i + 1] = _memoryQuestion.counterReponses[i];
		}
		return resultsQuestion;
    }

	// return question data (for interface web)
    function getQuestionData(structQuestion storage _memoryQuestion) internal view returns (reacQuestion memory) {
        reacQuestion memory oneQuestion;
		oneQuestion.titre = _memoryQuestion.titre;
		oneQuestion.question = _memoryQuestion.question;
		oneQuestion.reponses = _memoryQuestion.reponses;
		return oneQuestion;
    }

	// From interface web ****************************
	// delete question
    function deleteQuestion(structQuestion storage _memoryQuestion) internal returns (bool) {
		_memoryQuestion.deleted = true;
		return true;
    }
*/
	// ***********************************************************
	// fonctions Questionnaire ***********************************
	// ***********************************************************
/*
	// For interface web ****************************
	// return questions list for interface web
    function getListQuestions(structQuestionnaire storage _memoryQuestionnaire) internal view returns (reacQuestion[] memory) {
		reacQuestion[] memory listQuestions;
		delete listQuestions;
		for( uint i = 0; i < _memoryQuestionnaire.questions.length; i++) {
		    if(_memoryQuestionnaire.questions[i].deleted)
				continue;
			listQuestions[listQuestions.length] = getQuestionData(_memoryQuestionnaire.questions[i]);
		}
		return listQuestions;
    }
*/
	/*
	// return all questions list () view and deleted) for interface web
     function getListAllQuestions() internal view returns (bytes32[] memory) {
		reacQuestion[] memory listQuestions;
		delete listQuestions;
		for( uint i = 0; i < _memoryQuestionnaire.questions.length; i++) {
			listQuestions[listQuestions.length] = getQuestionData(_memoryQuestionnaire.questions[i]);
		}
		return listQuestions;
    }
	*/
/*
	// From interface web ****************************
	// convert reacQuestion to struct questions and add to questionnaire
    function addQuestion(structQuestionnaire storage _memoryQuestionnaire, reacQuestion memory _reacQuestion) internal returns (bool) {
		structQuestion storage newQuestion = _memoryQuestionnaire.questions.push();
		newQuestion.deleted = false;
		newQuestion.isexist = true;
        newQuestion.titre = _reacQuestion.titre;
		newQuestion.question = _reacQuestion.question;
		newQuestion.reponses = _reacQuestion.reponses;
		newQuestion.counter = 0;
		for (uint i = 0; i < newQuestion.reponses.length; i++) {
		    newQuestion.counterReponses[i] = 0;
		}
		return true;
    }

	// ajout plusieurs questions
    function addQuestions(structQuestionnaire storage _memoryQuestionnaire, reacQuestion[] memory _reacQuestion) internal returns (uint) {
		uint i;
		for (i = 0; i < _reacQuestion.length; i++) {
		    if(!addQuestion(_memoryQuestionnaire, _reacQuestion[i])) break;
		}
		return i;
	}
*/
	// ***********************************************************
	// fonctions Categories **************************************
	// ***********************************************************
	// check if categorie name exist, if exist return index otherwise return -1
	function getIndexCategorieByName(string memory _name) internal view returns (int) {
		for (uint i = 0; i < categories.length; i++) {
			if (keccak256(abi.encodePacked(categories[i].name)) == keccak256(abi.encodePacked(_name)))
		    	return int(i);
		}
		return int(-1);
	}

/*
	// For interface web ****************************
	// return listCategorie / listquestionnaire / listQuestion

	// return questions list for interface web
	// noExistQuestionnaire(uint _reacQuestionnaire.indexCategorie, uint _reacQuestionnaire.index)
    function getListQuestions(reacQuestionnaire memory _reacQuestionnaire) public view returns (reacQuestion[] memory) {
		structQuestionnaire storage memoryQuestionnaire = categories[_reacQuestionnaire.indexCategorie].questionnaires[_reacQuestionnaire.index];
		return getListQuestions(memoryQuestionnaire);
	}

	// return questionnaire data (for interface web) // noExistQuestionnaire(uint _categorie, uint _questionnaire)
    function getInternalQuestionnaireData(uint _categorie, uint _questionnaire) internal view returns (reacQuestionnaire memory) {
        reacQuestionnaire memory oneQuestionnnaire;
		structQuestionnaire storage memoryQuestionnaire = categories[_categorie].questionnaires[_questionnaire];
		oneQuestionnnaire.indexCategorie = _categorie;
		oneQuestionnnaire.index = _questionnaire;
		oneQuestionnnaire.name = memoryQuestionnaire.name;
		oneQuestionnnaire.questions = memoryQuestionnaire.questions.length;
		return oneQuestionnnaire;
    }

	// noExistQuestionnaire(uint _reacQuestionnaire.indexCategorie, uint _reacQuestionnaire.index)
    function getQuestionnaireData(reacQuestionnaire memory _reacQuestionnaire) public view returns (reacQuestionnaire memory) {
		return getInternalQuestionnaireData(_reacQuestionnaire.indexCategorie, _reacQuestionnaire.index);
    }

	// return questionnaires list for interface web // noExistCategorie(uint _categorie)
	// noExistCategorie(uint _categorie)
	// noOwnerCategorie(uint _categorie)
    function getListQuestionnaires(uint _categorie) public view returns (reacQuestionnaire[] memory) {
		//require(categories[_categorie].owner == msg.sender, "not owner of this categorie !");
		reacQuestionnaire[] memory listQuestionnaires;
		delete listQuestionnaires;
		for( uint i = 0; i < _categorie; i++) {
			listQuestionnaires[listQuestionnaires.length] = getInternalQuestionnaireData(_categorie, i);
		}
		return listQuestionnaires;
	}
*/
	// From interface web ****************************
function getCount() public view returns(uint count) {
    return categories.length;
}

	// create categorie, return index of new categorie or -1 if error
	function createCategorie(string memory _name) public returns (bool) {
		// TODO : test si _name = ""
		if (keccak256(abi.encodePacked("")) == keccak256(abi.encodePacked(_name)))
			return false; //0; //int(-1);
		// check if categorie name already exist
		if (getIndexCategorieByName(_name) != (-1))
			return false; // 0; //int(-1);
		//return 0;

		//structCategories memory categorie;

		bytes32[] memory questionnaires;

		//categorie = structCategories(msg.sender, true, false, _name, questionnaires);
		//categories.push(categorie);

		categories.push(structCategories(msg.sender, true, false, _name, questionnaires));
		return true; //getCount(); //categories.length;
    }

	// get index of categorie by nam , if exist return index otherwise return -1
	function getCategorieIndexByName(string memory _name) public view returns (int) {
		return getIndexCategorieByName(_name);
	}
/*
	function deleteCategorieByIndex(uint _index) public returns (bool) {
		if (_index > (categories.length - 1))
			return false;
		categories[_index].deleted = true;
		return true;
	}

	function deleteCategorieByName(string memory _name) public returns (bool) {
		int index = getIndexCategorieByName(_name);
		if (index == (-1))
			return false;
		categories[uint(index)].deleted = true;
		return true;
	}
*/
	/*
    struct reacCategories {
		uint index;
        bool deleted;    // if true, ne plus afficher la categorie
		string name;
		uint questionnaires; // number of questionnaires in categorie
    }
	*/
/*
	// noOwnerCategorie(uint _categorie)
    function getInternalCategorieData(uint _categorie) internal view returns (reacCategories memory) {
		//require(categories[_categorie].owner == msg.sender, "not owner of this categorie !");
        reacCategories memory oneCategorie;
		oneCategorie.deleted = categories[_categorie].deleted;
		oneCategorie.name = categories[_categorie].name;
		oneCategorie.questionnaires = categories[_categorie].questionnaires.length;
		return oneCategorie;
    }

    function getListCategories() public view returns (reacCategories[] memory) {

		//if (categories.length == 0) {
		//    return reacCategories[];
		//}


		reacCategories[] memory listCategories;
		delete listCategories;
		for( uint i = 0; i < categories.length; i++) {
			if (categories[i].owner != msg.sender)
				continue;
			listCategories[listCategories.length] = getInternalCategorieData(i);
		}
		return listCategories;
	}



	// TODO : closeQuestionnaire

	// noExistCategorie(_reacQuestionnaire.indexCategorie)
	// noOwnerCategorie(uint _categorie)
    function addQuestionnaire(reacQuestionnaire memory _reacQuestionnaire) public returns (bool) {
		structQuestionnaire storage newQuestionnaire = categories[_reacQuestionnaire.indexCategorie].questionnaires.push();
		//newQuestionnaire.owner = msg.sender;
		newQuestionnaire.isexist = true;
		newQuestionnaire.close = false;
		newQuestionnaire.deleted = false;
		newQuestionnaire.name = _reacQuestionnaire.name;
		return true;
    }

	// noExistQuestionnaire(uint _reacQuestionnaire.indexCategorie, uint _reacQuestionnaire.index)
	function addQuestions(reacQuestionnaire memory _reacQuestionnaire, reacQuestion[] memory _reacQuestion) public returns (uint) {
		structQuestionnaire storage memoryQuestionnaire = categories[_reacQuestionnaire.indexCategorie].questionnaires[_reacQuestionnaire.index];
		return addQuestions(memoryQuestionnaire, _reacQuestion);
	}
*/

/*
	//modifier noExistQuestion(uint _categorie, uint _questionnaire, uint _question)
    function addVoteToQuestion(reacVote memory _reacVote) public returns (bool) {
		structQuestion storage memoryQuestion = categories[_reacVote.indexCategorie].questionnaires[_reacVote.indexQuestionnaire].questions[_reacVote.indexQuestion];
		bool result = addVote(memoryQuestion, _reacVote.sender, int(_reacVote.choice));
		if (!result) return false;
		// Update counters
		memoryQuestion.counter++;
		memoryQuestion.counterReponses[uint(_reacVote.choice)]++;
		return true;
	}

	//modifier noExistQuestion(uint _categorie, uint _questionnaire, uint _question) {
    function isVotedToQuestion(reacVote memory _reacVote) public view returns (bool) {
		structQuestion storage _memoryQuestion = categories[_reacVote.indexCategorie].questionnaires[_reacVote.indexQuestionnaire].questions[_reacVote.indexQuestion];
		return isVoted(_memoryQuestion, _reacVote.sender);
	}
*/
	/*
	// structure reacCategories
    struct reacCategories {
		uint index;
        bool deleted;    // if true, ne plus afficher la categorie
		string name;
		uint questionnaires; // number of questionnaires in categorie
    }

    struct reacVote {
		uint indexCategorie;
		uint indexQuestionnaire;
		uint indexQuestion;
		address sender;
        uint choice;
    }
	*/
	//structQuestion storage _memoryQuestion = categories[_categorie].questionnaires[_questionnaire].questions[_question];
	//structQuestionnaire storage _memoryQuestionnaire = categories[_categorie].questionnaires[_questionnaire];

}