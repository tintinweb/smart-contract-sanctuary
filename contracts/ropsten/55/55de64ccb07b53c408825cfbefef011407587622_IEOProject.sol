/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
//pragma solidity >=0.5.0 <0.9.0;
pragma solidity >=0.8.0 <0.9.0;

//compiler version 0.8.0 above got built in overflow check by default
//EIP-1066 : https://eips.ethereum.org/EIPS/eip-1066
//EIP-1400 : https://github.com/ethereum/eips/issues/1411
//require - It should be used to ensure valid conditions that cannot be detected until execution time.
//assert - test for internal errors, and to check invariants. Properly functioning code should never create a Panic, not even on invalid external input.

interface IEOProjKYC {
    function isVerifiedInvestor(address _investor) external view returns (bool);
}

error Err(bytes _ESC, bytes32 _reasons);
error FailedToSendEther(uint256 _weiValue, address _weiReceiver);

contract IEOProject {
    //-------------------------- Structure ----------------------------
    //Document
    struct Document {
        string docUri;
        bytes32 docHash;
        uint256 docLastUpdate;
        //Cannot delete mapping instead clearing, we set this to true false. default of bool is false
        bool docIsExist;
    }
    //-------------------------- State Variable ----------------------------

    bytes32 public name;
    bytes32 public symbols;
    uint8 public decimal;
    //Total amount of token available to be offered
    uint256 public totalSupply;
    //IEOSales price in Wei
    uint256 IEOSalesPrice;
    //IEOSales target
    uint256 IEOSalesTargetAmount;
    //Maximum amount of token can be issue to each investor
    uint256 IEOSalesHardCapPerUser;
    //Project start date ( timestamp as seconds since unix epoch )
    uint64 IEOSalesStartDate;
    //Project end date ( timestamp as seconds since unix epoch )
    uint64 IEOSalesEndDate;
    //Isssuer address to receive and refund investment
    address payable public issuerAddress;
    //IEO process operator
    address public IEOOperatorAddress;
    //IEOSales status
    IEOProcessStatus IEOSalesStatus;
    //indicate if the token is mintable or issuable
    bool isIssuableAfterIEO;
    address[] public IEOInvestors;
    address[] public defaulter;
    address[] public rejected;
    //The partitions available for this token
    IEOProjKYC kyc;

    //PARTITION AND BALANCE
    enum Partitions {
        IEO_Invest,
        Usable,
        Locked,
        Rejected
    }

    //IEO Status
    enum IEOProcessStatus {
        InProgress,
        Halted,
        Successful,
        Failed
    }
    //Storing list of investor and their investment amount
    mapping(address => mapping(Partitions => uint256)) balances;
    mapping(address => mapping(address => uint256)) allowed;

    //DOCUMENT
    //Storing list of document keys
    bytes32[] documentList;
    //Storing document details
    mapping(bytes32 => Document) document;

    //--------------------------- Constructor ------------------------

    //Only 1 constructor allowed
    //memory = temporary , storage = permenant, calldata = temporary and will not change the value
    constructor(
        //Arguments
        bytes32 _name,
        bytes32 _symbols,
        uint256 _IEOSalesPrice,
        uint256 _IEOSalesTargetAmount,
        uint256 _IEOSalesHardCapPerUser,
        uint64 _IEOSalesStartDate,
        uint64 _IEOSalesEndDate,
        address _issuerAddress,
        address _kyc
    ) {
        //Validation
        require(_IEOSalesEndDate > _IEOSalesStartDate, "Invalid sales period");

        //Initialization
        name = _name;
        symbols = _symbols;
        decimal = 18;
        IEOSalesPrice = _IEOSalesPrice;
        IEOSalesTargetAmount = _IEOSalesTargetAmount;
        IEOSalesHardCapPerUser = _IEOSalesHardCapPerUser;
        IEOSalesStartDate = _IEOSalesStartDate;
        IEOSalesEndDate = _IEOSalesEndDate;
        //Convert the address to type payable
        issuerAddress = payable(_issuerAddress);
        IEOOperatorAddress = msg.sender;
        isIssuableAfterIEO = true;
        IEOSalesStatus = IEOProcessStatus.InProgress;
        kyc = IEOProjKYC(_kyc);
    }

    //--------------------------- Modifiers ---------------------------
    //Anyone including IEO Operator, Issuer and Controller ( Declare requirements for calling functions )
    modifier authoritiesOnly() {
        //Call is valid function to check the sender is either issuer or operator.
        require(
            msg.sender == issuerAddress || msg.sender == IEOOperatorAddress,
            "Authorities only"
        );
        _; // Necessary for end statement
    }
    //Only IEO Operator is allowed
    modifier IEOOperatorOnly() {
        //check if the sender is IEOOperator
        require(msg.sender == IEOOperatorAddress, "IEO Operator only");
        _; // Necessary for end statement
    }
    //Only if the sales is successful
    modifier IEOSalesResultSuccessful() {
        require(
            IEOSalesStatus == IEOProcessStatus.Successful,
            "Only IEO Sales success"
        );
        _;
    }

    //---------------------------- Events ------------------------------
    //Invest event
    event NewInvestment( address indexed _investorAddress, uint256 _investment, uint256 _wei, uint256 _investmentDateTime, bytes _proof);
    event IEOSalesResult(string _result, uint256 _dateTime);
    //If halt, announce the total amount and also amount required
    event IEOSalesHalted(uint256 _dateTime, string _reasons);
    event IEOIssue( address indexed _investorAddress, uint256 _tokenAmount, uint256 _issueDateTime);
    event IEORefund(address indexed _investorAddress, uint256 _tokenAmount, uint256 _weiRefunded, uint256 _refundDateTime);
    event RewardIssuer( address _issuerAddress, uint256 _rewardedAmount, uint256 _dateTime );

    //Document event
    //Indexed allow the user to search logged event by indexed parameter ( Primary Key ?)
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed( address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    // Controller Events
    event ControllerTransfer(address _controller, address indexed _from, address indexed _to, uint256 _value, bytes _data, bytes _operatorData);
    event ControllerRedemption(address _controller, address indexed _tokenHolder, uint256 _value, bytes _data, bytes _operatorData);

    //ERC-20 Events
    //When the user approve certain address to transfer token from them
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //For transfer with data event, data within parameter would be descriptive metadata.
    event TransferWithData(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    //--------------------------- Functions ----------------------------------------
    //--------------------------- IEO RELATED --------------------------------------
    //For IEO Investment
    //For everyone to get the details of the project token
    //Containing state variable only, excluding document list, controller list, investor list.
    function tokenDetails()
        external
        view
        returns (
            bytes32,
            bytes32,
            uint256,
            uint256,
            uint256,
            uint64,
            uint64,
            address,
            string memory,
            uint256,
            uint8
        )
    {
        return (
            name,
            symbols,
            totalSupply,
            IEOSalesTargetAmount,
            IEOSalesHardCapPerUser,
            IEOSalesStartDate,
            IEOSalesEndDate,
            issuerAddress,
            getIEOSalesStatus(),
            IEOSalesPrice,
            decimal
        );
    }
    //Let anyone to have a look on the IEO sales status
    function getIEOSalesStatus() public view returns (string memory _status) {
        if (IEOSalesStatus == IEOProcessStatus.Successful) {
            _status = "Successful";
        } else if (IEOSalesStatus == IEOProcessStatus.Failed) {
            _status = "Failed";
        } else if (IEOSalesStatus == IEOProcessStatus.Halted) {
            _status = "Halted";
        } else if (
            block.timestamp < IEOSalesStartDate &&
            IEOSalesStatus == IEOProcessStatus.InProgress
        ) {
            _status = "Preparing";
        } else if (isWithinIEOSalesPeriod()) {
            _status = "Ongoing";
        } else if (
            IEOSalesStatus == IEOProcessStatus.InProgress &&
            block.timestamp > IEOSalesEndDate
        ) {
            _status = "Pending conclude";
        }
    }
    //IEO invest functions
    function IEOInvest(uint256 _investment, bytes calldata _data) external payable {
        //call canIEOInvest, returning bool flag and reasons ( thinking to be customize code or reasons)
        (bytes memory ESC, bytes32 codeDet) = canIEOInvest( msg.sender, _investment, msg.value, _data);
        //Must be validated only can invest
        if( ESC[0] != hex"01"){
            revert(string(abi.encodePacked(codeDet)));
            //revert Err({ _ESC: ESC, _reasons: codeDet});
        }

        //Do your invest here
        //In the case the investor is not first time invest.
        if (balances[msg.sender][Partitions.IEO_Invest] == 0) {
            //Store into investors list for redemption afterwards
            IEOInvestors.push(msg.sender);
        }

        //Increase the Invest partition of the sender
        balances[msg.sender][Partitions.IEO_Invest] += _investment;
        //Increase total supply
        totalSupply += _investment;
        //Emit event announce new investment
        emit NewInvestment(msg.sender, _investment,  msg.value, block.timestamp, _data);
    }
    //Do necessary checking to validate if suitable to invest
    function canIEOInvest(
        address _investor,
        uint256 _investment,
        uint256 _etherAttatched,
        bytes calldata _data
    ) internal view returns (bytes memory _ESC, bytes32 _codeDet) {

        _ESC = hex"01";
        _codeDet = "Ok";
        //CHECKLIST
        //1. If within sales period
        //2. If reached hard capacity of each user
        //3. Should be KYC verified
        //4. Should not exceed the target sales
        //5. Check if the ether attatched same with the investment they want to
        //6. All the authorities are prohibited
        //7. Check if the IEO Operator signed the data

        //check 1
        if (!isWithinIEOSalesPeriod()){
            _ESC = hex"18";
            _codeDet = "Within IEO Sales Period Only";
        }
        //check 2
        else if (remainingSalesToken() < _investment) {
            _ESC = hex"04";
            _codeDet = "Token supplement insufficient";
        }
        //check 3
        else if (!kyc.isVerifiedInvestor(_investor)) {
            //0x16 = banned
            _ESC = hex"16";
            _codeDet = "Investor not whitelisted";
        }
        //check 4
        else if (balances[_investor][Partitions.IEO_Invest] + _investment > IEOSalesHardCapPerUser) {
            //0x56 - Transfer Volume Exceeded
            _ESC = hex"56";
            _codeDet = "Hard capacity exceeded";
        }
        //check 5
        else if (investmentToWei(_investment) != _etherAttatched) {
            //0x28 - Duplicate, Conflict, or Collision
            _ESC = hex"28";
            _codeDet = "Ether attached not equivalent";
        }
        //check 6
        else if ( msg.sender == issuerAddress || msg.sender == IEOOperatorAddress ) {
            _ESC = hex"16";
            _codeDet = "Authorities are prohibited";
        }
        //check 7
        else if ( checkIEOInvestSigned(msg.sender, _investment, _data) != IEOOperatorAddress ) {
            //0xE4 - Unsigned or Untrusted
            _ESC = hex"E4";
            _codeDet = "Not signed by IEO Operator";
        }
    }
    //Halt the IEO Sales
    function haltIEOSales(string calldata _reasons) external IEOOperatorOnly {
        require(block.timestamp < IEOSalesStartDate, "Before IEO sales only");
        //Change status to halted
        IEOSalesStatus = IEOProcessStatus.Halted;
        //emit event to announce the Sales process halted
        emit IEOSalesHalted(block.timestamp, _reasons);
    }
    //Generate IEO Sales result
    //Do token issuance and refunds
    function concludeIEOSales() external IEOOperatorOnly {
        //Need to be in pending conclude status period
        require(
            IEOSalesStatus == IEOProcessStatus.InProgress &&
                block.timestamp > IEOSalesEndDate,
            "After IEO Sales only"
        );

        //Check if hit target raise amount
        if (totalSupply == IEOSalesTargetAmount) {
            //If project consider success

            //Change all the investors' balances in invest partitions to usable partitions
            for (uint256 i = 0; i < IEOInvestors.length; i++) {
                //Investment partitions = usable
                balances[IEOInvestors[i]][Partitions.Usable] = balances[
                    IEOInvestors[i]
                ][Partitions.IEO_Invest];
                //Clear investment partitions
                delete balances[IEOInvestors[i]][Partitions.IEO_Invest];
                //call event issued
                emit IEOIssue(
                    IEOInvestors[i],
                    balances[IEOInvestors[i]][Partitions.Usable],
                    block.timestamp
                );
            }

            //Send collected ether for issuer
            uint256 collectedWei = address(this).balance;
            sendEther(issuerAddress, collectedWei);
            emit RewardIssuer(issuerAddress, collectedWei, block.timestamp);

            //Change status to successful
            IEOSalesStatus = IEOProcessStatus.Successful;
            //Announce IEO success
            emit IEOSalesResult("Successful", block.timestamp);
        } else {
            //If project consider failed
            //Refund all the investors' balances in invest partitions
            for (uint256 i = 0; i < IEOInvestors.length; i++) {
                uint256 investment = balances[IEOInvestors[i]][
                    Partitions.IEO_Invest
                ];

                //Decrease total supply
                totalSupply -= investment;

                //Clear investment balances of investors
                delete balances[IEOInvestors[i]][Partitions.IEO_Invest];

                //get wei to be refund to investor
                uint256 invInWei = investmentToWei(investment);
                //call internal function refund ether
                sendEther(IEOInvestors[i], invInWei);
                //emit event
                emit IEORefund(
                    IEOInvestors[i],
                    investment,
                    invInWei,
                    block.timestamp
                );
            }

            //Change status to failed
            IEOSalesStatus = IEOProcessStatus.Failed;
            //Announce IEO failed
            emit IEOSalesResult("Failed", block.timestamp);
        }

        //clear defaulter list ( Their locked partitions do not do any effect on this)
        rejected = defaulter;
        delete defaulter;
        for(uint256 i = 0; i < rejected.length; i ++){
            balances[rejected[i]][Partitions.Rejected] = balances[rejected[i]][Partitions.Locked];
        }
    }
    //Let people to view current fund raising progresss
    function remainingSalesToken() public view returns (uint256) {
        uint256 result = IEOSalesTargetAmount - totalSupply;
        return result;
    }
    //Let people to check if within the IEO sales period
    function isWithinIEOSalesPeriod() internal view returns (bool) {
        return
            block.timestamp >= IEOSalesStartDate &&
            block.timestamp <= IEOSalesEndDate &&
            IEOSalesStatus == IEOProcessStatus.InProgress;
    }
    //Let people to check their total investment
    function IEOInvestment(address _address) external view returns (uint256) {
        return balances[_address][Partitions.IEO_Invest];
    }
    function investmentToWei(uint256 _inv) internal view returns (uint256) {
        //Numerator
        uint256 invN = _inv / (1 * (10**decimal));
        //Denomenator
        uint256 invD = _inv % (1 * (10**decimal));

        uint256 r1 = IEOSalesPrice * invN;
        uint256 r2 = (IEOSalesPrice * invD) / (1 * (10**decimal));

        return r1 + r2;
    }
    //Check the signature provided by IEOOperator using ecrecover
    //recover the address associated with the public key from elliptic curve signature or return zero on error. The function parameters correspond to ECDSA values of the signature:
    //https://docs.soliditylang.org/en/latest/units-and-global-variables.html#mathematical-and-cryptographic-functions
    //r = first 32 bytes of signature
    //s = second 32 bytes of signature
    //v = final 1 byte of signature
    function checkIEOInvestSigned(address _investor, uint256 _investment, bytes memory sign) internal pure returns (address _recoveredAddress) {
        //Many library will prepend this header, 32 indicate the message length
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        //Contract generate hash for investment details
        bytes32 hash = keccak256(abi.encodePacked(_investor,_investment));
        //Then hash the hash generated beforehand along with the prefixed header
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(prefix, hash));
        //Get the r,s,v from the signature
        //length must equal to 65 - 32+32+1
        require(sign.length == 65, "Invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
           r := mload(add(sign, 32))
           // second 32 bytes
           s := mload(add(sign, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sign, 96)))
        }
        //Use ecrecover
        _recoveredAddress =  ecrecover(ethSignedMessageHash, v, r, s);
    }
    function sendEther(address _receiver, uint256 _value) internal{
        //check if the contract balance is still enough sin
        if(address(this).balance < _value){
            revert("Insufficient Ether");
            //revert Err({ _ESC: hex"04", _reasons: "Insufficient Ether"});
        }
        //Send ether to the address using the smart contract
        (bool callResult, bytes memory data) = _receiver.call{
            value: _value
        }("");
        //Check if the send is successful, return false if failed.
        //Must use require to revert all the state, else failed to send ether but changed the state
        if(!callResult){
            //50 stand for transfer failed
            revert("Fail to send ether");
            //revert Err({ _ESC: hex"50", _reasons: "Fail to send ether"});
        }
    }

    //ERC-1643 -> Document Management 
    //calldata most cheapest -> cannot modify value stored inside the variable but memory can
    //return the document uri, hash, and last update
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256){
        require(document[_name].docIsExist, "Document missing");
        return (
            document[_name].docUri,
            document[_name].docHash,
            document[_name].docLastUpdate
        );
    }
    //create or update document
    function setDocument( bytes32 _name, string calldata _uri, bytes32 _documentHash ) external authoritiesOnly {
        //Need to check if document exists
        //If document not exists, need to add into document list
        if (!document[_name].docIsExist) {
            //Add name into document list
            documentList.push(_name);
            //Set exists to true
            document[_name].docIsExist = true;
        }
        //Value assignment
        document[_name].docUri = _uri;
        document[_name].docHash = _documentHash;
        document[_name].docLastUpdate = block.timestamp;
        //call event document set
        emit DocumentUpdated(_name, _uri, _documentHash);
    }
    //Remove document
    function removeDocument(bytes32 _name) external authoritiesOnly {
        //check document exist
        require(document[_name].docIsExist, "Document requested does not exists");
        bool foundFlag = false;
        //find element
        for (uint256 i = 0; i < documentList.length && !foundFlag; i++) {
            //If found element
            if (documentList[i] == _name) {
                //Set found flag = true to stop searching
                foundFlag = true;
                //copy last to existing ( to delete the existing column)
                documentList[i] = documentList[documentList.length - 1];
                //remove last
                documentList.pop();
            }
        }
        //change doc exist to false
        delete document[_name].docIsExist;
        //call event document deleted
        emit DocumentRemoved( _name, document[_name].docUri, document[_name].docHash);
    }
    //Get all document
    function getAllDocuments() external view returns (bytes32[] memory) {
        return documentList;
    }
    function getAllInvestors() external view returns (address [] memory){
        return IEOInvestors;
    }

    //ERC-1644 -> Controller Operation
    //Only for the usage after IEO sales
    //Pure - wont read and also write the state variable
    function isControllable() public pure returns (bool) {
        //Can only control during IEO progress
        return true;
    }
    //Allow controller to transfer balance of from  partition to partition
    //In the case caught law legislation during IEO process, IEO operator better transfer the token under address(0), no one have private key for this address.
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData ) external authoritiesOnly {
        //check if this token contract is controllable
        require(isControllable(), "Not Controllable");
        //check if value is > 0
        require(_value > 0, "Invalid transfer value");

        Partitions p;
        if (IEOSalesStatus == IEOProcessStatus.InProgress) {
            p = Partitions.IEO_Invest;
            require(msg.sender == IEOOperatorAddress, "IEOOperatorOnly");
            require(balances[_from][p] >= _value, "Transferrer insufficient balance!");
             //If the from address balance become 0
            if (balances[_from][p] - _value == 0 && _from != address(0)) {
                removeFromInvestorList(_from);
            }

            //If to address balance originally is 0
            //After balance increment if still same value then means ori is 0
            if ( balances[_to][p] == 0 && _to != address(0)) {
                IEOInvestors.push(_to);
            }
        }else {
            p = Partitions.Usable;
        }

        //If to address is 0x0 indicate its actually fund locked. 
        if(_to == address(0)){
            if(balances[_from][Partitions.Locked] == 0){
                defaulter.push(_from);
            }
            totalSupply -= _value;
            balances[_from][Partitions.Locked] += _value;
        }
        //If from address is 0x0 indicate its actually released locked funds. 
        if(_from == address(0)){
            //When returning need check if within the locked balance
            if(lockedBalanceOf(_to) < _value){
                revert("Exceed locked balance");
            }
            totalSupply += _value;
            balances[_to][Partitions.Locked] -= _value;
            //If after deduct there is no locked partitions already
            //remove from defaulter list
            if( balances[_to][Partitions.Locked] == 0){
                bool foundFlag = false;
                for ( uint256 i = 0; i < defaulter.length && !foundFlag; i++) {
                    if (defaulter[i] == _to) {
                        defaulter[i] = defaulter[defaulter.length - 1];
                        defaulter.pop();
                        foundFlag = true;
                    }
                }
            }
        }

        require(balances[_from][p] >= _value, "Transferrer insufficient balance!");
        //Decrease from address balance
        balances[_from][p] -= _value;
        //Increase to address balance
        balances[_to][p] += _value;

        //emit event
        emit ControllerTransfer( msg.sender, _from, _to, _value, _data, _operatorData);
    }
    //Allow controller to redeem usable partition balance and return ether back to the address.
    //In the case got complaint from investor want to refund their investment
    //For redemption function, data submitted will be use for commands
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData ) external authoritiesOnly {
        //check if this token contract is controllable
        require(isControllable(), "Not controllable");
        //check if value is > 0
        require(_value > 0, "Invalid redeem value");

        Partitions p;

        //check if the current sales status
        if (bytes32(_data) == bytes32("IEO_Investment")) {
            require(msg.sender == IEOOperatorAddress, "IEO Operator Only");
            require(IEOSalesStatus == IEOProcessStatus.InProgress, "IEO Sales Only");
            //Decrease total supply
            totalSupply -= _value;
            p = Partitions.IEO_Invest;
            if (balances[_tokenHolder][p] >= _value && balances[_tokenHolder][p] - _value == 0) {
                removeFromInvestorList(_tokenHolder);
            }
        }else if(bytes32(_data) == bytes32("Usable")){
            //Decrease total supply
            totalSupply -= _value;
            p = Partitions.Usable;
        }
        else if(bytes32(_data) == bytes32("Rejected")){
            require(IEOSalesStatus != IEOProcessStatus.InProgress, "Cannot within IEO Sales");
            p = Partitions.Rejected;
            if (balances[_tokenHolder][p] >= _value && balances[_tokenHolder][p] - _value == 0) {
                bool foundFlag = false;
                for ( uint256 i = 0; i < rejected.length && !foundFlag; i++) {
                    if (rejected[i] == _tokenHolder) {
                        rejected[i] = rejected[rejected.length - 1];
                        rejected.pop();
                        foundFlag = true;
                    }
                }
            }
        }
        else{
            revert("Invalid command");
        }

        require(balances[_tokenHolder][p] >= _value, "Redeemer insufficient balance");
        balances[_tokenHolder][p] -= _value;
        sendEther(_tokenHolder, investmentToWei(_value));

        //emit event
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }
    //Let investor to check their locked balance
    function lockedBalanceOf(address _owner) public view returns (uint256 balance){
        balance = balances[_owner][Partitions.Locked];
    }
    //Remove fraudulant from investor list
    function removeFromInvestorList(address _investor) internal {
        bool foundFlag = false;
        for ( uint256 i = 0; i < IEOInvestors.length && !foundFlag; i++) {
            if (IEOInvestors[i] == _investor) {
                    IEOInvestors[i] = IEOInvestors[IEOInvestors.length - 1];
                    IEOInvestors.pop();
                    foundFlag = true;
            }
        }
    }
    //Rejected partitions 
    function rejectedOf(address _tokenHolder) external view returns (uint256 balance){
        balance = balances[_tokenHolder][Partitions.Rejected];
    }
    function getAllDefaulter() external view returns (address [] memory){
        return defaulter;
    }
    function getAllRejectedInvestor() external view returns (address [] memory){
        return rejected;
    }

    //ERC-1594 -> Core Security Token Standard
    //Need to figure out how to use transfer from function sin
    //In this standard the attatched data will be used as reference only (injecting off- chain data) for example a json file, or pdf file mentioning reasons
    // Transfers
    function transferWithData( address _to, uint256 _value, bytes calldata _data) external IEOSalesResultSuccessful {
        (bytes memory ESC, bytes32 codeDet) = canTransfer(_to, _value, _data);
        if(ESC[0] != hex"01"){
            revert(string(abi.encodePacked(codeDet)));
            //revert Err({ _ESC: ESC, _reasons: codeDet});
        }
        //Decrease from address balance
        balances[msg.sender][Partitions.Usable] -= _value;
        //Increase to address balance
        balances[_to][Partitions.Usable] += _value;
        //Emit event
        emit TransferWithData(msg.sender, _to, _value, _data);
    }
    function transferFromWithData( address _from, address _to, uint256 _value, bytes calldata _data) external IEOSalesResultSuccessful {
        ( bytes memory ESC, bytes32 codeDet ) = canTransferFrom(_from, _to, _value, _data);
        if(ESC[0] != hex"01"){
            revert(string(abi.encodePacked(codeDet)));
            //revert Err({ _ESC: ESC, _reasons: codeDet});
        }
        //Decrease from address balance
        balances[_from][Partitions.Usable] -= _value;
        //Increase to address balance
        balances[_to][Partitions.Usable] += _value;
        //Emit event
        emit TransferWithData(msg.sender, _to, _value, _data);
    }
    // Token Issuance
    function isIssuable() public view returns (bool) {
        //Check the token is still issuable - can be currently issuable but not later on
        return isIssuableAfterIEO;
    }
    function issue(
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data
    ) external authoritiesOnly IEOSalesResultSuccessful {
        //check if issuable sin
        require(isIssuable(), "Not issuable");
        //increase total supply
        totalSupply += _value;
        //increase balance of token holder
        balances[_tokenHolder][Partitions.Usable] += _value;
        // Issuance / Redemption Events
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }
    // Transfer Validity
    function canTransfer( address _to, uint256 _value, bytes calldata _data )internal view returns (bytes memory _ESC, bytes32 _codeDet)
    {
        //Default Successful
        _ESC = hex"01";
        _codeDet = "Ok";

        //CHECKLIST
        //1. If the value is valid
        //2. If the transferrer have enough balances.
        //3. Can only transfer after IEO sales
        //4. If only the transferrer is still whitelisted ( THE ISSUER SHOULD HAVE THEIR OWN KYC WHITELIST, BUT I ASSUME WE SHARING THE SAME WHITELIST)
        //5. If only the receiver is still whitelisted

        //check 1
        if (_value <= 0) {
            //24 stand for below range or underflow
            _ESC = hex"24";
            _codeDet = "Invalid value";
        }
        //check 2
        else if (balanceOf(msg.sender) < _value) {
            //54 stand for Insufficient funds
            _ESC = hex"54";
            _codeDet = "Insufficient balance";
        }
        //check 3
        else if (IEOSalesStatus != IEOProcessStatus.Successful) {
            //18 Not Applicable to Current State
            _ESC = hex"18";
            _codeDet = "If only IEO sales successful";
        }
        //check 4
        else if (!kyc.isVerifiedInvestor(msg.sender)){
            _ESC = hex"16";
            _codeDet = "Transferrer is not whitelisted";
        }
        //check 5
        else if (!kyc.isVerifiedInvestor(_to)){
            //A* Application Specific Codes 
            _ESC = hex"16";
            _codeDet = "Receiver is not whitelisted";
        }
    }
    function canTransferFrom( address _from, address _to, uint256 _value, bytes calldata _data ) internal view returns ( bytes memory _ESC, bytes32 _codeDet)
    {
        _ESC = hex"01";
        _codeDet = "Ok";
        //CHECKLIST
        //1. If the value is valid
        //2. If the transferrer have enough balances.
        //3. Can only transfer after IEO sales
        //4. If only the transferrer is still whitelisted ( THE ISSUER SHOULD HAVE THEIR OWN KYC WHITELIST, BUT I ASSUME WE SHARING THE SAME WHITELIST)
        //5. If only the receiver is still whitelisted
        //6. If only the caller have enough allowance from the transferrer
        //7. If only the caller himself is also KYC verified

        //check 1
        if (_value <= 0) {
            //24 stand for below range or underflow
            _ESC = hex"24";
            _codeDet = "Invalid value";
        }
        //check 2
        else if (balances[_from][Partitions.Usable] < _value) {
            //54 stand for Insufficient funds
            _ESC = hex"54";
            _codeDet = "Insufficient balance";
        }
        //check 3
        else if (IEOSalesStatus != IEOProcessStatus.Successful) {
            //18 Not Applicable to Current State
            _ESC = hex"18";
            _codeDet = "After IEO Sales only";
        }
        //check 4
        else if (!kyc.isVerifiedInvestor(_from)){
            _ESC = hex"16";
            _codeDet = "Transferrer is not whitelisted";
        }
        //check 5
        else if (!kyc.isVerifiedInvestor(_to)){
            _ESC = hex"16";
            _codeDet = "Receiver is not whitelisted";
        }
        //check 6
        else if(allowance(_from, msg.sender) < _value) {
            //26 Above Range or Overflow
            _ESC = hex"26";
            _codeDet = "Allowance insufficient";
        }
        //Check 7
        else if (!kyc.isVerifiedInvestor(msg.sender)){
            _ESC = hex"16";
            _codeDet = "Caller is not whitelisted";
        }
    }
    // Token Redemption
    function redeem(uint256 _value, bytes calldata _data) external IEOSalesResultSuccessful
    {
        //check if the redeemer balance is still enough sin
        require(balances[msg.sender][Partitions.Usable] >= _value, "Redeemer insufficient balance!");
        require(kyc.isVerifiedInvestor(msg.sender), "Not whitelisted");

        //decrease total supply
        totalSupply -= _value;
        //Decrease usable balances of token holder
        balances[msg.sender][Partitions.Usable] -= _value;
        //Send ether to the address using the smart contract
        sendEther(msg.sender, investmentToWei(_value));
        //emit event
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }
    //Should have allowance function
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external IEOSalesResultSuccessful {
        //check if the redeemer from balance is still enough sin
        require(balances[_tokenHolder][Partitions.Usable] >= _value, "The redeemer have insufficient balance!");
        //check if sufficient allowance for redeem
        require(allowed[_tokenHolder][msg.sender] < _value, "Allowance insufficient");

        //decrease total supply
        totalSupply -= _value;
        //Decrease usable balances of token holder
        balances[_tokenHolder][Partitions.Usable] -= _value;
        //Send ether to the address using the smart contract
        sendEther(msg.sender, investmentToWei(_value));
        //emit event
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }
    //ERC-20 remaining function
    function balanceOf(address _owner) public view returns (uint256 balance){
        balance = balances[_owner][Partitions.Usable];
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        success = true;
        emit Approval(msg.sender, _spender, _value);
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        remaining =  allowed[_owner][_spender];
    }
}