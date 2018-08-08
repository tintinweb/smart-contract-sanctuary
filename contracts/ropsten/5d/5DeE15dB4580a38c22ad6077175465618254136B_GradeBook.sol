pragma solidity ^0.4.21;

contract GradeBook {

  event EvaluationRecorded(uint32 indexed recorderID, uint32 indexed studentID, uint32 indexed activity, uint64 evaluationID); 

  // The core evaluation method. The order is important because the optimizer
  // crams together the smaller fields in storage.
  struct Evaluation {
    uint32 recorderID;
    uint32 studentID;
    uint32 activity;
    uint8 complexity;
    uint8 effort;
    uint8 weight;
    uint8 points;
    uint8 weightedPoints;
  }

  modifier onlyValidStudentID(uint32 studentID) {
    require(studentID <= studentCount);
    _;
  }

  // student IDs mapped to the external unique identifier
  // this is normalized to minimize the size of the evaluations array.
  mapping(bytes => uint32) internal studentByID;
  bytes[] internal students;
  uint32 internal studentCount;

  // recorder IDs mapped to the Ethereum address which recorded them
  // this is normalized to minimize the size of the evaluations array.
  mapping(address => uint32) internal recorderByAddress;
  address[] internal recorders;
  uint32 internal recorderCount;

  // evaluations stored in a public array
  // accessible through the implicit evaluations() function.
  // and mapped from student and recorder
  Evaluation[] public evaluations;
  mapping(uint32 => uint64[]) internal evaluationsByStudentID;
  mapping(uint32 => uint64[]) internal evaluationsByRecorderID;

  // Constructor
  function GradeBook() public {
    studentCount = 0;
    recorderCount = 0;
  }

  // Retrieve the number of student identifiers defined
  function getStudentCount() public view returns (uint32) {
    return studentCount;
  }

  // Retrieve the student ID based on the text-based student identifier
  // "zero" means the student is not recorded in the system.
  function getStudentID(bytes idText) public view returns (uint32) {
    return studentByID[idText];
  }

  // Retrieve the text-based student identifier based on the student ID
  function getStudentIDText(uint32 studentID) public view returns (bytes) {
    // studentID is one-based, array is zero-based
    return students[studentID-1];
  }

  // Public function to establish an internal student ID which corresponds
  // to an external student ID (which must be unique).
  function makeStudentID(bytes idText) public returns (uint32) {
    // must not already exist
    require(0 == getStudentID(idText));
    students.push(idText);
    studentCount = studentCount + 1;
    studentByID[idText] = studentCount;
    return studentCount;
  }

  // Get the internal recorder ID which corresponds to the Ethereum address
  // of the recorder.
  function getRecorderID(address recorder) public view returns (uint32) {
    return recorderByAddress[recorder];
  }

  // get the Ethereum address which corresponds to the internal recorder ID
  function getRecorderAddress(uint32 recorderID) public view returns (address) {
    // recorderID is one-based, array is zero-based
    return recorders[recorderID-1];
  }

  // Record an evaluation. The only restriction is that the student ID must be valid;
  // otherwise, *anyone* can create an evaluation with any values for any activity,
  // real or imaginary, legit or bogus.
  function recordEvaluation(
    uint32 studentID,
    uint32 activity,
    uint8 complexity,
    uint8 effort,
    uint8 weight,
    uint8 points,
    uint8 weightedPoints) public onlyValidStudentID(studentID)
    {

    // look up the Recorder ID. If none exists, assign one.
    uint32 recorderID = makeRecorderID();

    // Store the evaluation in the public evaluations array
    evaluations.push(Evaluation(
      recorderID,
      studentID,
      activity,
      complexity,
      effort,
      weight,
      points,
      weightedPoints));

    // Add the evaluation to the maps so it can be looked up by the student
    // or by the recoder
    uint64 evaluationID = uint64(evaluations.length - 1);
    evaluationsByRecorderID[recorderID].push(evaluationID);
    evaluationsByStudentID[studentID].push(evaluationID);

    // Send an event for this evaluation
    emit EvaluationRecorded(recorderID, studentID, activity, evaluationID);
  }

  // Retrieve the total number of evaluations
  function getEvaluationCount() public view returns (uint64) {
    return uint64(evaluations.length);
  }

  // Retrieve the number of evaluations by the recorder
  function getEvaluationCountByRecorderID(uint32 recorderID) public view returns (uint64) {
    return uint64(evaluationsByRecorderID[recorderID].length);
  }

  // Retrieve the number of evaluations for the student
  function getEvaluationCountByStudentID(uint32 studentID) public view returns (uint64) {
    return uint64(evaluationsByStudentID[studentID].length);
  }

  // Retrieve an evaluation by a recorder at a given zero-based index
  function getEvaluation(uint64 index) public view
    returns (uint32 recorderID, address recorderAddress, uint32 studentID, bytes studentIDText, uint32 activity, uint8 complexity, uint8 effort, uint8 weight, uint8 points, uint8 weightedPoints)
  {
    Evaluation storage evalu = evaluations[index];
    return(
      evalu.recorderID,
      getRecorderAddress(evalu.recorderID),
      evalu.studentID,
      getStudentIDText(evalu.studentID),
      evalu.activity,
      evalu.complexity,
      evalu.effort,
      evalu.weight,
      evalu.points,
      evalu.weightedPoints);
  }

  // Retrieve an evaluation by a recorder at a given zero-based index
  function getEvaluationByRecorderID(uint32 recorderID, uint64 index) public view
    returns (uint32 studentID, bytes studentIDText, uint32 activity, uint8 complexity, uint8 effort, uint8 weight, uint8 points, uint8 weightedPoints)
  {
    Evaluation storage evalu = evaluations[evaluationsByRecorderID[recorderID][index]];
    return(
      evalu.studentID,
      getStudentIDText(evalu.studentID),
      evalu.activity,
      evalu.complexity,
      evalu.effort,
      evalu.weight,
      evalu.points,
      evalu.weightedPoints);
  }

  // Retrieve an evaluation for a student at a given zero-based index
  function getEvaluationByStudentID(uint32 studentID, uint64 index) public view
    returns (uint32 recorderID, address recorderAddress, uint32 activity, uint8 complexity, uint8 effort, uint8 weight, uint8 points, uint8 weightedPoints)
  {
    Evaluation storage evalu = evaluations[evaluationsByStudentID[studentID][index]];
    return(
      evalu.recorderID,
      getRecorderAddress(evalu.recorderID),
      evalu.activity,
      evalu.complexity,
      evalu.effort,
      evalu.weight,
      evalu.points,
      evalu.weightedPoints);
  }

  // Internal function for the generation of a recorder ID. The recorder is the sender
  // of the transaction, is not otherwise modifiable, which is why this is internal only.
  function makeRecorderID() internal returns (uint32) {
    uint32 recorderID = getRecorderID(msg.sender);
    if ( 0 == recorderID ) {
      recorders.push(msg.sender);
      recorderCount = recorderCount + 1;
      recorderByAddress[msg.sender] = recorderCount;
      recorderID = recorderCount;
    }
    return recorderID;
  }
}