/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.6.12;
pragma experimental 'ABIEncoderV2';

contract EternalStorage {
    
  struct SUBJECT {
    string subject_id;  
    string overall_score;
  }

  struct TRANSCRIPT {
    string student_id;
    uint256 created_at;
    string subject_ids;
    string overall_scores;
    mapping(string => SUBJECT) assigned_subjects;
  }

  mapping(string => TRANSCRIPT) internal studentTranscripts;
  
}


contract studentTranscripts is EternalStorage {
  event studentTranscriptsInserted(string student_id);


  function insertStudentTranscript(
    string memory _student_id,
    string[] memory _subject_ids,
    string[] memory _overall_scores) public {
    
    TRANSCRIPT memory studentTranscript = TRANSCRIPT(_student_id, now, '', '');
    studentTranscripts[_student_id] = studentTranscript;
    
    string memory subjectIdsConcat = '';
    string memory overallScoresConcat = '';
    
    for (uint i = 0; i < _subject_ids.length; i++) {
    
        SUBJECT memory assignedSubject = SUBJECT(_subject_ids[i], _overall_scores[i]);  
        
        subjectIdsConcat = string(abi.encodePacked(subjectIdsConcat,',',assignedSubject.subject_id));
        
        overallScoresConcat = string(abi.encodePacked(overallScoresConcat,',',assignedSubject.overall_score));
        
        studentTranscripts[_student_id].assigned_subjects[assignedSubject.subject_id] = assignedSubject;
    
    }
    
    studentTranscripts[_student_id].subject_ids = substring(subjectIdsConcat,1, bytes(subjectIdsConcat).length);
    studentTranscripts[_student_id].overall_scores = substring(overallScoresConcat,1, bytes(overallScoresConcat).length);
    
    emit studentTranscriptsInserted(_student_id);

    }
    
    
  function getStudentTranscript(string memory _student_id) public view returns
    (
    string memory student_id_,
    uint256 created_at_,
    string memory subject_ids_,
    string memory overall_scores_
    )
    
    {
        
    TRANSCRIPT memory studentTranscript = studentTranscripts[_student_id];
    return  
    (
    studentTranscript.student_id,
    studentTranscript.created_at,
    studentTranscript.subject_ids,
    studentTranscript.overall_scores    
    );
        
    }

    function substring(string memory str, uint startIndex, uint endIndex) public view returns (string memory finalResult) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
    }

}