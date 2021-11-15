pragma solidity ^0.8.6;

// TEST

contract BlockchainUniversity {
    mapping(uint256 => bytes32) private answers;
    mapping(address => mapping(uint256 => bool)) public studentAnswersStatuses;
    mapping(address => uint256) public studentIdx;
    
    uint256 public numberOfStudents;
    uint256 public numberOfQuestions;
    address public teacher;
    struct Student {
        address id;
        string handle;
        uint256 enrollmentDate;
        bool graduated;
    }
    Student[] public students;
        
    modifier onlyTeacher() {
        require(msg.sender == teacher, "Teacher: Caller is not the teacher");
        _;
    }
    
    modifier onlyStudents() {
        require(studentIdx[msg.sender] > 0, "Teacher: Caller is not a student");
        _;
    }
    
    constructor() {
        teacher = msg.sender;
        initializeAnswersSeed();
    }
    
    function myIdx() public view returns (uint256) {
        return studentIdx[msg.sender];
    }
    
    function addAnswer(bytes32 answer) public onlyTeacher {
        answers[numberOfQuestions] = answer;
        numberOfQuestions++;
    }
    
    function addAnswers(bytes32[] memory _answers) public onlyTeacher {
        for (uint256 answerIdx; answerIdx < _answers.length; answerIdx++) {
            addAnswer(_answers[answerIdx]);
        }
    }

    function enroll(string memory handle) external {
        address studentId = msg.sender;
        if (studentIdx[studentId] > 0) {
            revert("Teacher: You are already enrolled");
        }
        Student memory student = Student({
            id: studentId,
            handle: handle,
            enrollmentDate: block.timestamp,
            graduated: false
        });
        students.push(student);
        numberOfStudents++;
        studentIdx[studentId] = numberOfStudents;
    }

    function studentRoll() external view returns (Student[] memory) {
        Student[] memory _studentRoll = new Student[](numberOfStudents);
        for (uint256 _studentIdx; _studentIdx < numberOfStudents; _studentIdx++) {
            _studentRoll[_studentIdx] = students[_studentIdx];
        }
        return _studentRoll;
    }

    function graduates() external view returns (address[] memory) {
        address[] memory _graduates = new address[](numberOfStudents);
        uint256 numberOfGraduates;
        for (uint256 _studentIdx; _studentIdx < numberOfStudents; _studentIdx++) {
            Student memory student = students[_studentIdx];
            if (student.graduated) {
                _graduates[numberOfGraduates] = student.id;
                numberOfGraduates++;
            }
        }
        bytes memory encodedAddresses = abi.encode(_graduates);
        assembly {
            mstore(add(encodedAddresses, 0x40), numberOfGraduates)
        }
        address[] memory filteredAddresses = abi.decode(encodedAddresses, (address[]));
        return filteredAddresses;
    }

    
    function enterAnswer(uint256 questionId, bytes32 answer) public onlyStudents {
        bool correctAnswer = checkAnswer(questionId, answer);
        require(correctAnswer, "Teacher: Incorrect answer");
        students[studentIdx[msg.sender] - 1].graduated = true;
    }

    function checkAnswer(uint256 questionId, bytes32 answer) public view onlyStudents returns (bool) {
        bytes32 correctAnswer = keccak256(abi.encodePacked(tx.origin, getAnswerFromQuestionId(questionId)));
        return answer == correctAnswer;
    }
    
    function getAnswerFromQuestionId(uint256 questionId) internal view returns (bytes32) {
        return getAnswerFromPointerWord(answers[questionId]);
    }

    function getAnswersSeedDistribution() internal view returns (bytes1[256] memory) {
        bytes1[256] memory randomDistribution;
        bytes memory seed = abi.encodePacked(teacher);
        uint16 idx;
        while (idx < randomDistribution.length) {
            seed = abi.encodePacked(keccak256(seed));
            uint16 randomNumber = uint16(uint256(keccak256(seed)));
            uint16 randomPointer = randomNumber - (randomNumber / 256) * 256;
            if (randomDistribution[randomPointer] == 0x00) {
                randomDistribution[randomPointer] = bytes1(uint8(idx));
                idx++;
            }
        }
        return randomDistribution;
    }

    function storeDistribution(bytes1[256] memory distributionArr) internal {
        bytes memory distribution = new bytes(256);
        uint256 offset = uint256(keccak256(abi.encodePacked(teacher)));
        for (uint256 idx = 0; idx < 256; idx++) {
            distribution[idx] = distributionArr[idx];
        }
        for (uint256 i = 0; i < 8; i++) {
            bytes32 temp;
            assembly {
                temp := mload(add(distribution, mul(0x20, add(i, 1))))
                mstore(0, temp)
                sstore(add(i, offset), mload(0))
            }
        }
    }
    
    function getDistribution() internal view returns (bytes1[256] memory) {
        uint256 offset = uint256(keccak256(abi.encodePacked(teacher)));
        bytes memory data = new bytes(256);
        bytes1[256] memory dataCompact;
        for (uint256 i = 0; i < 8; i++) {
            assembly {
                mstore(add(data, mul(32, add(i, 1))), sload(add(i, offset)))
            }
        }
        for(uint256 i = 0; i < 256; i++) {
            dataCompact[i] = data[i];
        }
        return dataCompact;
    }
    
    function initializeAnswersSeed() internal {
        bytes1[256] memory distributionArr = getAnswersSeedDistribution();
        storeDistribution(distributionArr);
    }
    
    function getPointerFromSeed(bytes1 rune) internal view returns (bytes1) {
        bytes1[256] memory distribution = getDistribution();
        for (uint8 ptr; ptr < 256; ptr++) {
            if (distribution[ptr] == rune) {
                return bytes1(ptr);
            }
            if (ptr == 255) {
                break;
            }
        }
        revert("Error getting pointer");
    }

    function generateAnswerPointerWord(bytes32 answer) internal view returns (bytes32) {
        bytes memory pointers = new bytes(32);
        for (uint8 i; i < 32; i++) {
            bytes1 pointer = getPointerFromSeed(answer[i]);
            pointers[i] = pointer;
        }
        return bytes32(pointers);
    }
        
    function getAnswerFromPointerWord(bytes32 pointerHash) internal view returns (bytes32) {
        bytes1[256] memory distribution = getDistribution();
        bytes memory response = new bytes(32);
        for (uint8 ptr; ptr < 32; ptr++) {
            bytes1 result = distribution[uint8(pointerHash[ptr])];
            response[ptr] = result;
        }
        return bytes32(response);
    }
}

