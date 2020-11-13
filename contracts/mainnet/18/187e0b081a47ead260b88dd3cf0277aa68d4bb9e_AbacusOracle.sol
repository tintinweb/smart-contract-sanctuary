//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract AbacusOracle is Initializable{
    
    using SafeMath for uint256;
    
    address payable owner;
    
    uint public callFee;
    uint public jobFee;
    uint public jobsActive;
    uint64[] private jobIds;
    uint callId;
    
    enum Status {ACTIVE,CLOSED}
        
    /*============Mappings=============
    ----------------------------------*/
    
    mapping (uint64 => Job) public jobs;
    mapping (uint64 => uint[]) private jobResponse;
    mapping (uint64 => bool) public isJobActive;
    mapping (address => bool) private isUpdater;
    mapping (uint => bytes32) public calls;

    /*============Events===============
    ---------------------------------*/
    
    event jobCreated(
        string api,
        bytes32 [] parameters,
        uint64 jobId
        );
        
    event breach(
        uint64 jobId,
        address creator,
        uint previousPrice,
        uint newPrice
        );
        
    event ScheduleFuncEvent(
        address indexed to, 
        uint256 indexed callTime,    
        bytes data,
        uint256 fee,
        uint256 gaslimit,
        uint256 gasprice, 
        uint256 indexed callID
        );
        
    event FunctionExec(
        address to,
        bool txStatus,
        bool reimbursedStatus
        );
    
    /*=========Structs================
    --------------------------------*/
    
    struct Job{
        string api;
        bytes32 [] parameters;
        string ipfsHash;
        address creator;
        uint NoOfParameters;
        uint triggerValue;
        uint dataFrequency;
        uint prepaidValue;
        uint leftValue;
        bool hashRequired;
        Status status;
    }
    
    
    /*===========Modifiers===========
    -------------------------------*/
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyUpdater(){
        require(isUpdater[msg.sender]);
        _;
    }  
    uint public totalOwnerFee;    
    function initialize(address payable _owner,uint _fee,uint _callFee , address[] memory _updaters) public initializer{
        owner =_owner;
        jobFee = _fee;
        isUpdater[_owner] =true;
        callFee = _callFee;
        
        for(uint i=0; i<_updaters.length;i++){
            isUpdater[_updaters[i]] = true;
        } 
    }
    // constructor  (address payable _owner,uint _fee,uint _callFee , address[] memory _updaters) public {
    //     owner =_owner;
    //     jobFee = _fee;
    //     isUpdater[_owner] =true;
    //     callFee = _callFee;
        
    //     for(uint i=0; i<_updaters.length;i++){
    //         isUpdater[_updaters[i]] = true;
    //     }
    // }
    
    
    /*===========Job functions============
    -------------------------------------*/

    function createJob(string calldata _api,
                       bytes32[] calldata _parameters, 
                       uint _triggerValue , 
                       uint _frequency , 
                       uint _prepaidValue, 
                       uint ipfsHashProof
                       ) 
                       external payable returns(uint _Id) 
                       {
        require(msg.value == _prepaidValue);
        bool _hashRequired = ipfsHashProof == 0 ? false:true;
        uint nop  = _parameters.length;
        uint64 _jobId = uint64(uint(keccak256(abi.encodePacked(_api,_triggerValue,now))));
        
        jobs[_jobId] = Job({api : _api,
                            parameters : _parameters,
                            ipfsHash : "",
                            creator : msg.sender,
                            triggerValue : _triggerValue,
                            dataFrequency : _frequency,
                            prepaidValue: msg.value,
                            leftValue: msg.value,
                            NoOfParameters : nop,
                            hashRequired : _hashRequired,
                            status : Status.ACTIVE
        });
        jobIds.push(_jobId);
        isJobActive[_jobId] = true;
        jobResponse[_jobId] = [uint(0)];
        jobsActive += 1 ;
        
        emit jobCreated(_api,_parameters,_jobId);
        
        return _jobId;
        }
    
    function updateJob(uint64 _jobId,uint[] calldata _values) external onlyUpdater {
        require(isJobActive[_jobId],"job closed or not exist");
        uint g1 = gasleft();
        
        if(breachCheck(_jobId,_values[0])){
            //breachUpdate()
            emit breach(_jobId,
                        jobs[_jobId].creator,
                        jobResponse[_jobId][0],
                        _values[0]
                        );
        }
        
        jobResponse[_jobId] = _values;
        
        uint gasUsed = g1 - gasleft();
        
        if(jobs[_jobId].leftValue < gasUsed + jobFee){
            jobs[_jobId].status = Status.CLOSED;
            isJobActive[_jobId] = false;
            jobsActive -= 1;
        }else{
            totalOwnerFee += jobFee;
            jobs[_jobId].leftValue -= gasUsed + jobFee;
        }
    }
    
    function setFee(uint _fee) public onlyOwner {
        jobFee = _fee;
    }
    
    function deactivateJob(uint64 _jobId) public onlyOwner{
        require(isJobActive[_jobId],"job closed or not exist");
        isJobActive[_jobId] = false;
        jobs[_jobId].status = Status.CLOSED;
        jobsActive -= 1;
    }
      function getJobParameters(uint64 _jobId) public onlyUpdater view returns(bytes32[] memory _parameters){
        return jobs[_jobId].parameters;
    }  
   
    
    function addUpdater(address _updater) public onlyOwner{
        isUpdater[_updater] =true;
    }
    
    function getJobIds() public onlyUpdater view returns(uint64[] memory Ids) {
        return jobIds;
    }
    
    function updateJobTrigger(uint64 _jobId,uint _triggerValue) public {
        require(jobs[_jobId].creator == msg.sender,"unauthorised");
        jobs[_jobId].triggerValue = _triggerValue;
    }
    
    function getJobResponse(uint64 _jobId) public view returns(uint[] memory _values){
        require(isJobActive[_jobId],"job closed");
        return jobResponse[_jobId];
    }
    
    function increasePrepaidValue(uint64 _jobId,uint amount) external payable{
        require(jobs[_jobId].creator == msg.sender,"unauthorised");
        require(msg.value == amount);
        jobs[_jobId].prepaidValue = jobs[_jobId].prepaidValue + amount;
        jobs[_jobId].leftValue = jobs[_jobId].leftValue + amount;
        jobs[_jobId].status = Status.ACTIVE;
        isJobActive[_jobId] = true;
        jobsActive += 1;        
    }
    /*==============Shcedule functions===============
    -----------------------------------------------*/
    
    function scheduleFunc(address to ,uint callTime, bytes calldata data , uint fee , uint gaslimit ,uint gasprice)external payable{
        require(msg.value == callFee.add(gaslimit.mul(gasprice)));
        callId += 1;
        totalOwnerFee += callFee; 
        calls[callId] = keccak256(abi.encodePacked(to,callTime,data,fee,gaslimit,gasprice));
       
        
        
        emit ScheduleFuncEvent(to ,callTime ,data ,fee , gaslimit ,gasprice,callId);
    }
    
    function execfunct(address to ,uint callTime, bytes calldata data , uint fee , uint gaslimit ,uint gasprice,uint _callId) external onlyUpdater  {
       
       require(calls[_callId] == keccak256(abi.encodePacked(to,callTime,data,fee,gaslimit,gasprice)));

       (bool txStatus,) = to.call(data);
       
       (bool success,) = to.call{value:gasleft() -200}("");       
       delete calls[_callId];
       
       emit FunctionExec(to,txStatus,success);

    }
    
    function setCallFee(uint _callFee) public onlyOwner {
         callFee = _callFee;
    }

    /*==============Helpers============
    ---------------------------------*/
    
    function breachCheck(uint64 _jobId, uint newvalue) private view returns(bool) {
        uint _value = jobResponse[_jobId][0];
        
        if(newvalue >= _value){return false;}
        
        uint change = ((_value - newvalue)*100)/_value ;
        return (change > jobs[_jobId].triggerValue );
    }
    
    
    function bytes32ToString(bytes32 x) public pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    function stringToBytes32(string memory str) public pure returns(bytes32 result){
       assembly {
            result := mload(add(str, 32))
        }
    }
   function withdraw(uint amount) public onlyOwner{
        require(amount<= totalOwnerFee,"insufficient balance");
        owner.transfer(amount);
    }
}