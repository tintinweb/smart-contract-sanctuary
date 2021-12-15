// File: @openzeppelin/contracts/utils/Counters.sol



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: Enums.sol


pragma solidity ^0.8.0;

library Enums {

    enum CallbackStatus {
        Ok, 
        Error 
    }

    enum ErrorCode {
        CommonInvalidCallbackIndex, 
        CommonInvalidRootObjectId,
        CommonInvalidFolderId,
        CommonInvalidContractorId,
        CommonValidateError,
        CommonRootHashError,
        CommonInvalidSignature,
        CommonInvalidSender,
        GeneralException,
        CommonInvalidEventCode,
        CommonFailDelegateCall,
        CommonInvalidSequenceEventCode,
        CommonInvalidMigrate
    }

    enum EventStatus {
        Started, 
        Finished
    }
}
// File: ApplicationWorkflow.sol


pragma solidity ^0.8.0;



contract ApplicationWorkflow {
    using Counters for Counters.Counter;

    address _owner;
    address _externalSystemAddress;

    mapping(uint8 => mapping(string => SignableEntity)) _signableEntities; //Key EntityType -> (Key: RootObjectId - Value: SignableEntity)
    mapping(uint16 => string) _functionsValidate; //Key Id -> uint(Enums.EventCode)
    mapping(uint16 => string) _externalEvents; //Key Id -> uint(Enums.EventCode)
    mapping(bytes32 => bool) validQueryIds;
    Counters.Counter _callbackCounter;
    mapping(uint256 => bool) _validCallbackIndex;
    mapping(uint16 => bool) _validEventCode;
    mapping(uint256 => uint16) _callbackEventCode;
    mapping(uint16 => string) _errorCodes;
    mapping(uint16 => string) _eventsName;
    mapping(uint16 => string) _eventValidationName;
    mapping(uint16 => bool) _requireValidation;
    mapping(uint16 => string) _statusCodes;
    mapping(uint256 => uint256) _callbackParent; //Key: callbackIndex  - Value: callbackIndex Parent
    string _logDomainEventsDefault = "logApplicationWorkflowEvent(string,string,string,uint256,uint8,string,string)";
    string _logValidateEventsDefault = "logApplicationWorkflowValidationEvent(string,string,string,uint256,uint8,string,string,address)";
    uint16 _updateRootHashCode;
    bool _allowMigration;
    mapping(address => mapping(uint8 => mapping(string => uint))) public _nonce; //Key identity -> (Key EntityType -> (Key: RootObjectId - Value: uint))

    //Rules Sequence EvenCode
    mapping(string => uint16[]) _eventCodesByRootObjectId; //Key: rootObjectId  - Value: array of eventCodes
    mapping(uint16 => bool) _mayBeFirst; //key: eventCode
    mapping(uint16 => uint16[]) _rulesSequence; //key: eventCode

    
    //#region Eventos
    event ApplicationWorkflowEvent(
        string,
        string,
        string,
        uint256,
        uint8,
        string,
        string,
        uint256
    );
    event ApplicationWorkflowValidationEvent(
        string,
        string,
        string,
        uint256,
        uint8,
        string,
        uint256,
        string,
        address
    );
    event UpdateRootHashEvent(string, string, uint256, uint8, string);
    //#region Eventos

    struct SignableEntity {
        bytes id;
        bool isCreated;
        bytes rootHash;
    }

    constructor(
        address externalSystemAddress,
        int256 initCallbackId,
        uint16 updateRootHashCode
    )  {
        _owner = msg.sender;
        _externalSystemAddress = externalSystemAddress;
        _validEventCode[updateRootHashCode] = true;
        _updateRootHashCode = updateRootHashCode;
        initCodes();
        initCallback(initCallbackId);
        setRules(updateRootHashCode, true, new uint16[](0x0));
        _allowMigration = false;
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidSender)]
        );
        _;
    }

    modifier onlyExternalSystem() {
        require(
            _externalSystemAddress == msg.sender,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidSender)]
        );
        _;
    }
    
    modifier onlyValidEventCode(uint16 eventCode) {
        require(
            _validEventCode[eventCode],
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidEventCode)]
        );
        _;
    }

    
    modifier onlyValidEventCodeSequence(string memory rootObjectId, uint16 eventCode) {
        bool validSequenceEventCode;
        // Si no tiene secuencia y puede ser el primero -> es valido
        // Si no tiene secuencia y no puede ser el primero -> es invalido
        // Si tiene secuencia, no tiene reglas de secuencia -> es valido
        // Si tiene secuencia, tiene reglas de secuencia y el ultimo eventCode esta dentro de la reglas es valido, sino es invalido

        //_mayBeFirst; //key: eventCode
        //_rulesSequence; //key: eventCode
        if( _eventCodesByRootObjectId[rootObjectId].length == 0)
        {
            if (_mayBeFirst[eventCode])
            {
                validSequenceEventCode = true;
            }
            else
            {
                validSequenceEventCode = false;
            }
        }
        else
        {
            uint16 lastEventCode = _eventCodesByRootObjectId[rootObjectId][_eventCodesByRootObjectId[rootObjectId].length-1];
            validSequenceEventCode = (_rulesSequence[eventCode].length > 0) ? false : true;
            uint index = 0;
            while (!validSequenceEventCode && index < _rulesSequence[eventCode].length)
            {
                if(_rulesSequence[eventCode][index] == lastEventCode)
                {
                    validSequenceEventCode = true;
                }
                index++;
            }
        }

        require(
            validSequenceEventCode,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidSequenceEventCode)]
        );
        _;
    }

    function initCodes() private {
        _errorCodes[uint16(
            Enums.ErrorCode.CommonInvalidCallbackIndex
        )] = "CommonInvalidCallbackIndex";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonInvalidRootObjectId
        )] = "CommonInvalidRootObjectId";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonValidateError
        )] = "CommonValidateError";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonRootHashError
        )] = "CommonRootHashError";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonInvalidSignature
        )] = "CommonInvalidSignature";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonInvalidSender
        )] = "CommonInvalidSender";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonInvalidEventCode
        )] = "CommonInvalidEventCode";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonFailDelegateCall
        )] = "CommonFailDelegateCall";
        _errorCodes[uint16(
            Enums.ErrorCode.CommonInvalidSequenceEventCode
        )] = "CommonInvalidSequenceEventCode";
        
        _statusCodes[uint16(Enums.EventStatus.Started)] = "Started";
        _statusCodes[uint16(Enums.EventStatus.Finished)] = "Finished";
    }

    function initCallback(int256 initCallbackId) private {
        if (initCallbackId > 1) {
            int256 index = 0;
            while (index < initCallbackId - 1) {
                _callbackCounter.increment();
                index = index + 1;
            }
        }
    }

    function processEventContent(
        uint16 entityType,
        string memory rootObjectId,
        uint16 eventCode,
        string memory hashData,
        address from,
        bytes memory sig
    ) public onlyOwner() {
        
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), this, _nonce[from][uint8(entityType)][rootObjectId], from, "processEventContent", entityType, rootObjectId, eventCode, hashData));
        address signer = checkSignature(from, sig, hash, entityType, rootObjectId);
       _processEvent(entityType, rootObjectId, eventCode, hashData, signer);
    }
    
    
    function processEvent(
        uint16 entityType,
        string memory rootObjectId,
        uint16 eventCode,
        string memory hashData
    ) public onlyExternalSystem() {
        _processEvent(entityType, rootObjectId, eventCode, hashData, msg.sender);
    }

    function _processEvent(
        uint16 entityType,
        string memory rootObjectId,
        uint16 eventCode,
        string memory hashData, 
        address identity
    ) internal onlyValidEventCode(eventCode) onlyValidEventCodeSequence(rootObjectId, eventCode){
        require(
            (_updateRootHashCode != eventCode),
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidEventCode)]
        );
        
        _signableEntities[uint8(entityType)][rootObjectId].isCreated = true;
        startApplicationWorkflowEvent(rootObjectId, eventCode, 0);
            
        if (requireValidation(eventCode)) {
                startApplicationWorkflowValidationEvent(
                rootObjectId,
                eventCode,
                _callbackCounter.current(),
                hashData,
                identity
            );
        } else {
            startUpdateRootHash(rootObjectId, _callbackCounter.current());
        }
    }

    function processEventCallback(
        uint16 entityType,
        string memory rootObjectId,
        uint256 callbackIndex,
        Enums.CallbackStatus callbackStatus,
        string memory errorCode
    ) public onlyOwner() {
        bool success;
        require(
            _validCallbackIndex[callbackIndex],
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidCallbackIndex)]
        );
        require(
            _signableEntities[uint8(entityType)][rootObjectId].isCreated,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidRootObjectId)]
        );

        uint16 eventCodeOriginal = uint16(_callbackEventCode[callbackIndex]);
        //Se finaliza el evento de validacion (con o sin error)
        //en caso de error se devuelve el mismo status y error que me devolvi� el oracle
        (success,) = address(this).delegatecall(
            abi.encodeWithSignature(
                _functionsValidate[eventCodeOriginal],
                _eventValidationName[eventCodeOriginal],
                _statusCodes[uint16(Enums.EventStatus.Finished)],
                rootObjectId,
                callbackIndex,
                callbackStatus,
                errorCode,
                ""
            )
        );
        require(
            success,
            _errorCodes[uint16(Enums.ErrorCode.CommonFailDelegateCall)]
            );


        if (callbackStatus == Enums.CallbackStatus.Ok) {
            if (requireValidation(eventCodeOriginal)) {
                startUpdateRootHash(rootObjectId, callbackIndex);
            }
        } else {
            //Se finaliza el evento externo que solicito la validacion, ya que no resulto v�lida
            (success,) = address(this).delegatecall(
                abi.encodeWithSignature(
                    _externalEvents[eventCodeOriginal],
                    _eventsName[eventCodeOriginal],
                    _statusCodes[uint16(Enums.EventStatus.Finished)],
                    rootObjectId,
                    callbackIndex,
                    Enums.CallbackStatus.Error,
                    _errorCodes[uint16(Enums.ErrorCode.CommonValidateError)],
                    errorCode
                )
            );
            require(
            success,
            _errorCodes[uint16(Enums.ErrorCode.CommonFailDelegateCall)]
            );
        }
    }

    function updateRootHashCallback(
        uint16 entityType,
        string memory rootObjectId,
        uint256 callbackIndex,
        Enums.CallbackStatus callbackStatus,
        string memory errorCode,
        string memory data
    ) public onlyOwner() {
        Enums.CallbackStatus resultStatus = callbackStatus;
        string memory resultErrorCode = errorCode;
        if (callbackStatus == Enums.CallbackStatus.Ok) {
            //Se actualiza el rootHash
            _signableEntities[uint8(entityType)][rootObjectId].rootHash = bytes(
                data
            );
        } else {
            resultStatus = Enums.CallbackStatus.Error;
            resultErrorCode = _errorCodes[uint16(
                Enums.ErrorCode.CommonRootHashError
            )];
        }
        emit UpdateRootHashEvent(
            _statusCodes[uint16(Enums.EventStatus.Finished)],
            rootObjectId,
            callbackIndex,
            uint8(callbackStatus),
            errorCode
        );

        uint256 callbackIndexParent = _callbackParent[callbackIndex];
        if (callbackIndexParent != 0) {
            uint16 eventCodeExternal = uint16(
                _callbackEventCode[callbackIndexParent]
            );

            (bool success,) = address(this).delegatecall(
                abi.encodeWithSignature(
                    _externalEvents[eventCodeExternal],
                    _eventsName[eventCodeExternal],
                    _statusCodes[uint16(Enums.EventStatus.Finished)],
                    rootObjectId,
                    callbackIndexParent,
                    resultStatus,
                    resultErrorCode,
                    errorCode
                )
            );
            if (resultStatus == Enums.CallbackStatus.Ok)
            {
                _eventCodesByRootObjectId[rootObjectId].push(eventCodeExternal);
            }
        
            require(
            success,
            _errorCodes[uint16(Enums.ErrorCode.CommonFailDelegateCall)]
            );
        }
    }

    function requireValidation(uint16 eventCode) private view  onlyValidEventCode(eventCode) returns (bool) {
        return (_requireValidation[eventCode] &&
            _updateRootHashCode != eventCode);
        //El unico evento que no requiere validacion es el update del RootHash
    }

    function setCallback(uint16 eventCode, uint256 callbackParent) private onlyValidEventCode(eventCode) {
        _callbackCounter.increment();
        _callbackParent[_callbackCounter.current()] = callbackParent;
        //Registro el id del callback como valido
        _validCallbackIndex[_callbackCounter.current()] = true;
        //registro el evento asociado al id del callback
        _callbackEventCode[_callbackCounter.current()] = uint16(eventCode);
    }

    function startApplicationWorkflowEvent(
        string memory rootObjectId,
        uint16 eventCode,
        uint256 callbackParent
    ) private onlyValidEventCode(eventCode) {
        setCallback(eventCode, callbackParent);
        (bool success,) = address(this).delegatecall(
            abi.encodeWithSignature(
                _externalEvents[uint16(eventCode)],
                _eventsName[uint16(eventCode)],
                _statusCodes[uint16(Enums.EventStatus.Started)],
                rootObjectId,
                _callbackCounter.current(),
                uint8(Enums.CallbackStatus.Ok),
                "",
                ""
            )
        );
        require(
            success,
            _errorCodes[uint16(Enums.ErrorCode.CommonFailDelegateCall)]
            );
    }

    function startApplicationWorkflowValidationEvent(
        string memory rootObjectId,
        uint16 eventCode,
        uint256 callbackParent,
        string memory hashData,
        address identity
    ) private onlyValidEventCode(eventCode){
        setCallback(eventCode, callbackParent);
        (bool success,) = address(this).delegatecall(
            abi.encodeWithSignature(
                _functionsValidate[uint16(eventCode)],
                _eventValidationName[uint16(eventCode)],
                _statusCodes[uint16(Enums.EventStatus.Started)],
                rootObjectId,
                _callbackCounter.current(),
                Enums.CallbackStatus.Ok,
                "",
                hashData,
                identity
            )
        );
        require(
            success,
            _errorCodes[uint16(Enums.ErrorCode.CommonFailDelegateCall)]
            );
    }

    function startUpdateRootHash(
        string memory rootObjectId,
        uint256 callbackParent
    ) private {
        setCallback(_updateRootHashCode, callbackParent);
        emit UpdateRootHashEvent(
            _statusCodes[uint16(Enums.EventStatus.Started)],
            rootObjectId,
            _callbackCounter.current(),
            0,
            ""
        );
    }

    function getByEnum(uint8 enumId, uint256 callbackCounterIndex)
        public
        view
        returns (
            string memory,
            string memory,
            uint16,
            string memory,
            string memory, uint256
        )
    {
        return (
            _functionsValidate[uint16(enumId)],
            _externalEvents[uint16(enumId)],
            _callbackEventCode[callbackCounterIndex],
            _functionsValidate[uint16(
                _callbackEventCode[callbackCounterIndex]
            )],
            _externalEvents[uint16(_callbackEventCode[callbackCounterIndex])],
            _callbackParent[callbackCounterIndex]
        );
    }

    function logApplicationWorkflowEvent(
        string memory eventName,
        string memory eventStatus,
        string memory rootObjectId,
        uint256 callbackIndex,
        uint8 callbackStatus,
        string memory errorCode,
        string memory innerError
    ) public {
        uint256 rootCallbackId = getRootCallbackId(callbackIndex);
        emit ApplicationWorkflowEvent(
            eventName,
            eventStatus,
            rootObjectId,
            callbackIndex,
            callbackStatus,
            errorCode,
            innerError,
            rootCallbackId
        );
    }

    function logApplicationWorkflowValidationEvent(
        string memory eventName,
        string memory eventStatus,
        string memory rootObjectId,
        uint256 callbackIndex,
        uint8 callbackStatus,
        string memory errorCode,
        string memory hashData,
        address identity
    ) public {
        uint256 rootCallbackId = getRootCallbackId(callbackIndex);
        emit ApplicationWorkflowValidationEvent(
            eventName,
            eventStatus,
            rootObjectId,
            callbackIndex,
            callbackStatus,
            errorCode,
            rootCallbackId,
            hashData,
            identity
        );
    }

    function getRootCallbackId(uint256 callbackId)
        private
        view
        returns (uint256)
    {
        uint256 res = callbackId;
        uint256 resPrev = callbackId;
        while (res != 0) {
            resPrev = res;
            res = _callbackParent[resPrev];
        }
        return resPrev;
    }

    function setEventName(uint16 eventCode, string memory value)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        _eventsName[eventCode] = value;
    }

    function setEventValidationName(uint16 eventCode, string memory value)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        _eventValidationName[eventCode] = value;
    }

    function setLogDomainEvents(uint16 eventCode, string memory value)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        _externalEvents[eventCode] = value;
    }

    function setLogDomainEventsDefault(uint16 eventCode)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        setLogDomainEvents(eventCode, _logDomainEventsDefault);
    }

    function setLogValidateEvents(uint16 eventCode, string memory value)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        _functionsValidate[eventCode] = value;
        _requireValidation[eventCode] = true;
    }

    function setLogValidateEventsDefault(uint16 eventCode) private onlyOwner() onlyValidEventCode(eventCode) {
        setLogValidateEvents(eventCode, _logValidateEventsDefault);
    }

    function setRules(uint16 eventCode, bool mayBeFirst, uint16[] memory rulesSequence)
        private
        onlyOwner() onlyValidEventCode(eventCode)
    {
        _mayBeFirst[eventCode] = mayBeFirst;
        _rulesSequence[eventCode] = rulesSequence;
    }

function ecrecovery(bytes32 hash, bytes memory sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
    
        if (sig.length != 65) {
          return address(0);
        }
    
        assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := and(mload(add(sig, 65)), 255)
        }
    
        if (v < 27) {
          v += 27;
        }
    
        if (v != 27 && v != 28) {
          return address(0);
        }
    
        return ecrecover(hash, v, r, s);
      }
    
    function checkSignature(address identity, bytes memory sig, bytes32 hash, uint16 entityType, string memory rootObjectId ) internal returns(address) {
        address signer = ecrecovery(hash, sig);
        require(signer == identity, "signer <> identity");
        _nonce[signer][uint8(entityType)][rootObjectId]++;
        return signer;
    }

    function configureEventCode(
        uint16 eventCode,
        string memory eventName,
        string memory logDomainEvents,
        bool requireValidate,
        string memory eventValidationName,
        string memory logValidateEvents,
        bool mayBeFirst,
        uint16[] memory rulesSequence
    ) public onlyOwner() {
        require(
            (_updateRootHashCode != eventCode),
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidEventCode)]
        );

        _validEventCode[eventCode] = true;
        setEventName(eventCode, eventName);
        setLogDomainEvents(eventCode, logDomainEvents);

        if (requireValidate) {
            setEventValidationName(eventCode, eventValidationName);
            setLogValidateEvents(eventCode, logValidateEvents);
        }
        setRules(eventCode, mayBeFirst, rulesSequence);
    }

    function configureEventCodeDefault(
        uint16 eventCode,
        string memory eventName,
        bool requireValidate,
        string memory eventValidationName,
        bool mayBeFirst,
        uint16[] memory rulesSequence
    ) public onlyOwner() {

        configureEventCode(eventCode, eventName, _logDomainEventsDefault, requireValidate, eventValidationName, _logValidateEventsDefault, mayBeFirst, rulesSequence);
    }

    function verifyData(
        uint16 entityType,
        string memory rootObjectId,
        string memory data)  public view returns(bool)
    {
        require(
            _signableEntities[uint8(entityType)][rootObjectId].isCreated,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidRootObjectId)]
        );
        return keccak256(_signableEntities[uint8(entityType)][rootObjectId].rootHash) == keccak256(bytes(data));
    }

    function openMigration()  public onlyOwner()
    {
        _allowMigration = true;
    }
    
    function migrate(
        uint16 entityType,
        string memory rootObjectId,
        string memory data)  public onlyOwner()
    {
        require(
            _allowMigration,
            _errorCodes[uint16(Enums.ErrorCode.CommonInvalidMigrate)]
        );
        _signableEntities[uint8(entityType)][rootObjectId].isCreated = true;
        _signableEntities[uint8(entityType)][rootObjectId].rootHash = bytes(data);
    }
    
    function finishMigration()  public onlyOwner()
    {
        _allowMigration = false;
    }

}