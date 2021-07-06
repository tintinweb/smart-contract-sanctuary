/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Vote {

    address private contractOwner;
    int choice;

	// Objet Vote ****************************************
    struct Voter {
        bool voted;    // if true, that person already voted (only for mapping)
        address owner; // if vote is not anonymous
        bytes32 question;
        uint choice;   // index of the voted proposal
    }

	// tous les get et pour voter
    struct reactVote {
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
        //bool anonymousVote; // true if vote is anonymous
		string question;
		string image; // TODO : sur ipfs;
		string[] reponses;
    	//address[] votants;
		// compteurs
		uint counter;
		uint[] counterReponses;
    }

	// structure reactQuestion
    struct reactQuestion {
		uint indexCategorie;
		uint indexQuestionnaire;
		string titre;
		string question;
        //bool anonymousVote;
		string image;
		string[] reponses;
    }

	// Objet Questionnaire ****************************************
    struct structQuestionnaire {
    	address	owner;
		bool isexist;
        bool close;    // if true, questionnaire terminé
        bool deleted;    // if true, ne plus afficher le questionnaire
		string name;
		// TODO : string image sur ipfs;
		bytes32[] questionsIndex; // number of questions in questionnaire
	}

	// structure reactQuestionnaire
    struct reactQuestionnaire {
		uint indexCategorie;
		uint index;
		string name;
		// TODO : string image sur ipfs;
		uint questions; // number of questions in questionnaire
    }

	// Objet Categories ****************************************
    struct structCategories {
    	address	owner;
		bool isexist;
        bool deleted;    // if true, ne plus afficher la categorie
		string name;
		// TODO : string image sur ipfs;
    	bytes32[] questionnairesIndex;
	}

	// structure reactCategories
    struct reactCategories {
		uint index;
        bool deleted;    // if true, ne plus afficher la categorie
		string name;
		// TODO : string image sur ipfs;
		uint questionnaires; // number of questionnaires in categorie
    }

	mapping(bytes32 => Voter) votes;
	bytes32[] votesIndex;
	mapping(bytes32 => structQuestion) questions;
	mapping(bytes32 => structQuestionnaire) questionnaires;
	mapping(bytes32 => structCategories) categories;
    bytes32[] categoriesIndex;

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
        contractOwner = msg.sender;
        choice = -1;
        //emptyString = keccak256(abi.encodePacked(""));
    }

    // string s = string(abi.encodePacked("a", " ", "concatenated", " ", "string"));
    function uuId(address _address, bytes32 _addedParam) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_address,bytes32(block.timestamp),bytes32(_addedParam)));
    }

    //function uuIdCategorie(address _address, uint _numCategorie) internal view returns (bytes32) {
    //    return keccak256(abi.encodePacked(_address, bytes32(block.timestamp), _numCategorie));
    //}

	// ***********************************************************
	// fonctions Vote *** ****************************************
	// ***********************************************************
	// From interface web ****************************
    function addVote(bytes32 _idQuestion, uint _value) internal returns (bool) {
        // TODO : add keccak256() to sender ?
        require(!isVoted(_idQuestion), "already vote!");

		bytes32 vid = uuId(msg.sender, bytes32(abi.encodePacked(_idQuestion, "v", votesIndex.length)));

	    votes[vid].voted = true;
	    votes[vid].owner = msg.sender;
	    votes[vid].question = _idQuestion;
	    votes[vid].choice = _value;
	    votesIndex.push(vid);

		// Update counters
		questions[_idQuestion].counter++;
		questions[_idQuestion].counterReponses[_value]++;
		return true;
	}		

	// For interface web ****************************
    function isVoted(bytes32 _idQuestion) internal view returns (bool) {
        // TODO : add keccak256() to sender ?
        for (uint i = 0; i < votesIndex.length; i++) {
            if (votes[votesIndex[i]].owner == msg.sender && votes[votesIndex[i]].question == _idQuestion)
                return true;
        }
        return false;
    }

    function addVoteToQuestion(uint _categorie, uint _questionnaire, uint _question, uint _choice) public returns (bool) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
        bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "Questionnaire not exist!");
		bytes32 qid = categories[id].questionnairesIndex[_questionnaire];
		bytes32 idQuestion = questionnaires[qid].questionsIndex[_question];
		require(questions[idQuestion].isexist, "Question not exist!");

        // TODO : if (choice > reponses.length) return false;
        return addVote(idQuestion, _choice);
	}

    function isVotedToQuestion(uint _categorie, uint _questionnaire, uint _question) public view returns (bool) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
        bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "Questionnaire not exist!");
		bytes32 qid = categories[id].questionnairesIndex[_questionnaire];
		bytes32 idQuestion = questionnaires[qid].questionsIndex[_question];
		require(questions[idQuestion].isexist, "Question not exist!");

		return isVoted(idQuestion);
	}

	// ***********************************************************
	// fonctions Question ****************************************
	// ***********************************************************

	// For interface web ****************************
	// return question result (for interface web)
    function getCountQuestions(uint _categorie, uint _questionnaire) public view returns(uint count) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
		bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "questionnaire not exist!");
		bytes32 qid = categories[id].questionnairesIndex[_questionnaire];
        return questionnaires[qid].questionsIndex.length;
    }

    struct reactResultVote {
		uint[] result;
    }

    function getResultsVote(uint _categorie, uint _questionnaire, uint _question) public view returns (reactResultVote memory) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
        bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "Questionnaire not exist!");
		bytes32 qid = categories[id].questionnairesIndex[_questionnaire];
		id = questionnaires[qid].questionsIndex[_question];

        reactResultVote memory resultsQuestion;
        //resultsQuestion.result.push(questions[id].counter);
        resultsQuestion.result[0] = questions[id].counter;
		for (uint i = 0; i < questions[id].reponses.length; i++) {
		    resultsQuestion.result[i + 1] = questions[id].counterReponses[i];
		}
/*
        uint[] memory resultsQuestion;
        resultsQuestion[0] = questions[id].counter;
		for (uint i = 0; i < questions[id].reponses.length; i++) {
		    resultsQuestion[i + 1] = questions[id].counterReponses[i];
		}
*/
		return resultsQuestion;
    }

    function getResultsVoteYes(uint _categorie, uint _questionnaire, uint _question) public view returns (uint) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
        bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "Questionnaire not exist!");
		bytes32 qid = categories[id].questionnairesIndex[_questionnaire];
		id = questionnaires[qid].questionsIndex[_question];

        return questions[id].counter;
    }

	// return question data (for interface web)
    function getInternalQuestionData(bytes32 _idQuestion) internal view returns (reactQuestion memory) {
        reactQuestion memory oneQuestion;
        // TODO index question
		oneQuestion.titre = questions[_idQuestion].titre;
		oneQuestion.question = questions[_idQuestion].question;
		oneQuestion.image = questions[_idQuestion].image;
		oneQuestion.reponses = questions[_idQuestion].reponses;
		return oneQuestion;
    }

    function getQuestionData(uint _categorie, uint _questionnaire, uint _question) public view returns (reactQuestion memory) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
        bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "Questionnaire not exist!");
		bytes32 qid = categories[id].questionnairesIndex[_questionnaire];
		id = questionnaires[qid].questionsIndex[_question];

		reactQuestion memory oneQuestion = getInternalQuestionData(id);
		oneQuestion.indexCategorie = _categorie;
		oneQuestion.indexQuestionnaire = _questionnaire;
		return oneQuestion;
    }
/*
	// From interface web ****************************
	// delete question
    function deleteQuestion(structQuestion storage _memoryQuestion) internal returns (bool) {
		_memoryQuestion.deleted = true;
		return true;
    }
*/
	// convert reacQuestion to struct questions and add to questionnaire
    // TODO : reponses + compteurs
    function addQuestion(bytes32 _qid, string memory _titre, string memory _question, string memory _image, string[] memory _reponses) internal returns (bool) {
		bytes32 uid = uuId(msg.sender, bytes32(abi.encodePacked(_qid, "q", questionnaires[_qid].questionsIndex.length)));

		questions[uid].isexist = true;
		questions[uid].deleted = false;
		questions[uid].titre = _titre;
		questions[uid].question = _question;
		questions[uid].image = _image;
		questions[uid].reponses = _reponses;
		questions[uid].counter = 0;
		for (uint i = 0; i < _reponses.length; i++) {
		    questions[uid].counterReponses.push(0);
		}
		questionnaires[_qid].questionsIndex.push(uid);
		return true;
    }

	// noExistQuestionnaire(uint _reacQuestionnaire.indexCategorie, uint _reacQuestionnaire.index)
	function addQuestions(uint _categorie, uint _questionnaire, string memory _titre, string memory _question, string memory _image, string[] memory _reponses) public returns (bool) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
		bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "questionnaire not exist!");

		// test si _titre = ""
		if (keccak256(abi.encodePacked("")) == keccak256(abi.encodePacked(_titre)))
			return false;

		// test si _question = ""
		if (keccak256(abi.encodePacked("")) == keccak256(abi.encodePacked(_question)))
			return false;

		return addQuestion(categories[id].questionnairesIndex[_questionnaire], _titre, _question, _image, _reponses);
	}

/*
	// ajout plusieurs questions
    function addQuestions(structQuestionnaire storage _memoryQuestionnaire, reacQuestion[] memory _reacQuestion) internal returns (uint) {
		uint i;
		for (i = 0; i < _reacQuestion.length; i++) {
		    if(!addQuestion(_memoryQuestionnaire, _reacQuestion[i])) break;
		}
		return i;
	}
*/

/*
	// TODO : a faire
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

	// ***********************************************************
	// fonctions Questionnaire ***********************************
	// ***********************************************************
	// check if categorie name exist, if exist return index otherwise return -1
	function getIndexQuestionnaireByName(uint _categorie, string memory _name) internal view returns (int) {
		for (uint i = 0; i < categories[categoriesIndex[_categorie]].questionnairesIndex.length; i++) {
			if (keccak256(abi.encodePacked(questionnaires[categories[categoriesIndex[_categorie]].questionnairesIndex[i]].name)) == keccak256(abi.encodePacked(_name)))
		    	return int(i);
		}
		return int(-1);
	}

	// return questionnaire data (for interface web) // noExistQuestionnaire(uint _categorie, uint _questionnaire)
    function getInternalQuestionnaireData(uint _categorie, uint _questionnaire) internal view returns (reactQuestionnaire memory) {
        reactQuestionnaire memory oneQuestionnnaire;
        bytes32 id = categoriesIndex[_categorie];
        bytes32 qId = categories[id].questionnairesIndex[_questionnaire];

		oneQuestionnnaire.indexCategorie = _categorie;
		oneQuestionnnaire.index = _questionnaire;
		oneQuestionnnaire.name = questionnaires[qId].name;
		oneQuestionnnaire.questions = questionnaires[qId].questionsIndex.length;
		return oneQuestionnnaire;
    }

	// For interface web ****************************
    function getCountQuestionnaire(uint _categorie) public view returns(uint count) {
        bytes32 id = categoriesIndex[_categorie];
        return categories[id].questionnairesIndex.length;
    }

	function getQuestionnaireIndexByName(uint _categorie, string memory _name) public view returns (int) {
		for (uint i = 0; i < categories[categoriesIndex[_categorie]].questionnairesIndex.length; i++) {
			if (keccak256(abi.encodePacked(questionnaires[categories[categoriesIndex[_categorie]].questionnairesIndex[i]].name)) == keccak256(abi.encodePacked(_name)))
		    	return int(i);
		}
		return int(-1);
	}

	// noExistQuestionnaire(uint _reacQuestionnaire.indexCategorie, uint _reacQuestionnaire.index)
    function getQuestionnaireData(uint _categorie, uint _questionnaire) public view returns (reactQuestionnaire memory) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
        bytes32 id = categoriesIndex[_categorie];
		require(_questionnaire < categories[id].questionnairesIndex.length, "Questionnaire not exist!");

		return getInternalQuestionnaireData(_categorie, _questionnaire);
    }

	// From interface web ****************************
	// TODO : closeQuestionnaire

	// noExistCategorie(_reacQuestionnaire.indexCategorie)
	// noOwnerCategorie(uint _categorie)
    function addQuestionnaire(uint _categorie, string memory _name) public returns (bool) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");
		// test si _name = ""
		if (keccak256(abi.encodePacked("")) == keccak256(abi.encodePacked(_name)))
			return false;
		// check if questionnaires name already exist
		if (getIndexQuestionnaireByName(_categorie, _name) != (-1))
			return false;

		bytes32 id = categoriesIndex[_categorie];
		bytes32 uid = uuId(msg.sender, bytes32(abi.encodePacked("C", _categorie ,"Q", categories[id].questionnairesIndex.length)));

		questionnaires[uid].owner = msg.sender;
		questionnaires[uid].isexist = true;
		questionnaires[uid].deleted = false;
		questionnaires[uid].name = _name;
		categories[id].questionnairesIndex.push(uid);
		return true;
    }

	// ***********************************************************
	// fonctions Categories **************************************
	// ************************************************************
	// check if categorie name exist, if exist return index otherwise return -1
	function getIndexCategorieByName(string memory _name) internal view returns (int) {
		for (uint i = 0; i < categoriesIndex.length; i++) {
			if (keccak256(abi.encodePacked(categories[categoriesIndex[i]].name)) == keccak256(abi.encodePacked(_name)))
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
*/
/*
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
	// TODO : getQuestionnaireIndex()
*/
	// From interface web ****************************
    function getCountCategorie() public view returns(uint count) {
        return categoriesIndex.length;
    }

	// create categorie, return indextrue or false if error
	function createCategorie(string memory _name) external returns (bool) {
		// test si _name = ""
		if (keccak256(abi.encodePacked("")) == keccak256(abi.encodePacked(_name)))
			return false;
		// check if categorie name already exist
		if (getIndexCategorieByName(_name) != (-1))
			return false;

		bytes32 uid = uuId(msg.sender, bytes32(abi.encodePacked("C", categoriesIndex.length)));

		categories[uid].owner = msg.sender;
		categories[uid].isexist = true;
		categories[uid].deleted = false;
		categories[uid].name = _name;
		categoriesIndex.push(uid);
		return true;
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
	// noOwnerCategorie(categoriesIndex[_categorie])
    function getCategorieData(uint _categorie) external view returns (reactCategories memory) {
		require(_categorie < categoriesIndex.length, "categorie not exist!");

		bytes32 id = categoriesIndex[_categorie];
		//require(categories[_categorie].owner == msg.sender, "not owner of this categorie !");
        reactCategories memory oneCategorie;
		oneCategorie.index = _categorie;
		oneCategorie.deleted = categories[id].deleted;
		oneCategorie.name = categories[id].name;
		oneCategorie.questionnaires = categories[id].questionnairesIndex.length;
		return oneCategorie;
    }

/*
	// noOwnerCategorie(uint _categorie)
    function getInternalCategorieData(uint _categorie) internal view returns (reactCategories memory) {
		//require(categories[_categorie].owner == msg.sender, "not owner of this categorie !");
        reactCategories memory oneCategorie;
		oneCategorie.deleted = categories[_categorie].deleted;
		oneCategorie.name = categories[_categorie].name;
		oneCategorie.questionnaires = categories[_categorie].questionnaires.length;
		return oneCategorie;
    }

    function getListCategories() public view returns (reactCategories[] memory) {

		//if (categories.length == 0) {
		//    return reactCategories[];
		//}


		reactCategories[] memory listCategories;
		delete listCategories;
		for( uint i = 0; i < categories.length; i++) {
			if (categories[i].owner != msg.sender)
				continue;
			listCategories[listCategories.length] = getInternalCategorieData(i);
		}
		return listCategories;
	}
*/

}