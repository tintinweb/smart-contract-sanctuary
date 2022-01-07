/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity ^0.5.0;

contract Bihu
{
    string public name; 
    uint public postCountQuestion; 
    mapping(uint => Question) public questions; 

    struct Question
    {
        uint id; 
        string question; 
        string label; 
        uint ansCount; 
        mapping(uint => Answer) answers; 
        address payable author; 
    }

    struct Answer
    {
        uint id; 
        string answer;
        uint tipAmount;
        address payable author; 
    }

    event QuestionCreated 
    (
        uint id, 
        string question, 
        string label, 
        address payable author 
    );

    event AnswerCreated 
    (
        uint id, 
        string answer, 
        address payable author 
    );

    event SearchingCreated 
    (
        string searching, 
        uint [] results 
    );

    constructor() public 
    {
        name = "Bihu";
    }

    function createQuestion(string memory _question, string memory _label) public 
    {
        require(bytes(_question).length > 0 && bytes(_label).length > 0); 
        postCountQuestion++;
        questions[postCountQuestion] = Question(postCountQuestion, _question, _label, 0, msg.sender); 
        emit QuestionCreated(postCountQuestion, _question, _label, msg.sender); 
    }

    function createAnswer(uint _id, string memory _answer) public 
    {
        require(bytes(_answer).length > 0); 
        questions[_id].ansCount++; 
        questions[_id].answers[questions[_id].ansCount] = Answer(postCountQuestion, _answer, 0, msg.sender); 
        emit AnswerCreated(postCountQuestion, _answer, msg.sender); 
    }

    function createSearching(string memory _searching) public 
    {
        require(bytes(_searching).length > 0); 
        uint[] memory _searchingresult = new uint[](postCountQuestion+1); 
        for(uint i = 1; i <= postCountQuestion; i++)
        {
            if(stringMatching(questions[i].question, _searching) == true || stringMatching(questions[i].label, _searching) == true)
            {
                _searchingresult[i] = 1; 
            }
        }
        emit SearchingCreated(_searching, _searchingresult); 
    }

    function stringMatching(string memory str, string memory substr) pure private returns(bool) 
    {
        bool res = false;
        uint len_str = bytes(str).length;
        uint len_substr = bytes(substr).length;
        if(len_str < len_substr)
        {
            string memory tmp;
            tmp = str;
            str = substr;
            substr = tmp;
        }
        bytes memory byte_str = bytes(str);
        bytes memory byte_substr = bytes(substr);
        for(uint i = 0; i < len_str; i++)
        {
            if(byte_str[i] == byte_substr[0])
            {
                for(uint j = 1; j < len_substr; j++)
                {
                    if(byte_str[i+j] != byte_substr[j])
                    {
                        break;
                    }
                    if(j == len_substr-1)
                    {
                        res = true;
                    }
                }
            }
            if(res == true)
            {
                break;
            }
        }
        return res;
    }

    function getAnswer(uint _id, uint _ans) public view returns(uint, string memory, uint, address) 
    {
        Answer memory _answer = questions[_id].answers[_ans];
        return (_answer.id, _answer.answer, _answer.tipAmount, _answer.author);
    }
}