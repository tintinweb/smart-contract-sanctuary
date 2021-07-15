/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

contract ADKContract {
 
/*
This is the main wADK Contract (ERC20 Implementation): Ethereum wrapped AidosKuneen Token.

The purpose of this contract is to enable transfer of ADK Token from/to the ADK Mesh to/from the Ethereum Blockchain 

For details see https://github.com/adkmaster/adk-ethereum-bridge

How it works (short version):

Transfers from Mesh to Ethereum (ADK to wADK):

ADK holders on the ADK Mesh transfer the amount of ADK they wish to convert to wADK (1:1 conversion) to the ADK Mesh address ADK_DEPOSIT_ADDRESS_LIVE. The signature part (=Message/Smart Data Section) of the + ADK transaction has to contain the encoded 'receiving' Ethereum Address (use functions USR_ETHAddrEncode 
and USR_ETHAddrDecode to convert from ADK SmartData String to Ethereum Adress and vice versa)

Once the ADK transaction has been confirmed on the ADK Mesh, the issuance of wADK will be triggered by the Contract owner specified in mainMeshOwner. The original ADK will remain locked in the ADK_DEPOSIT_ADDRESS_LIVE (and previous ADK deposit addresses) until a request for a conversion transaction wADK-->ADK is triggered (see below). 


Transfers from Ethereum (wADK) to Mesh (ADK):

wADK holders can request a transfer from the Ethereum Blockchain back to the Mesh (1:1 conversion) by calling the contract function "USR_transferToMesh". Registered requests will be executed periodically, with ADK to be issued from previously locked ADK, at which time a new public ADK_DEPOSIT_ADDRESS_LIVE will be generated as needed.

********************************************************************************************************************
DISCLAIMER: THE CROSS-CHAIN COMPONENT OF THIS CONTRACT IS **NOT** A TRUSTLESS BRIDGE, AS THAT WOULD REQUIRE ADK TO IMPLEMENT SMART CONTRACT CAPABILITIES. INSTEAD, THIS CONTRACT (the MESH-ETHEREUM Bridge Part) NEEDS TO BE OPERATED BY A TRUSTED PARTY, e.g. the Aidos Foundation (Milestone Server Operator) OR TRUSTED DELEGATE. 

Note: THIS ONLY APPLIES TO THE TRANSFER FROM/TO THE MESH. ONCE ISSUED, wADK FOLLOW THE ERC20 STANDARD (TRUSTLESS TRANSACTIONS)

********************************************************************************************************************

Fur further details, step by step HOW-TOs, and latest updates please see https://github.com/adkmaster/adk-ethereum-bridge
*/
    
    uint256 public totalSupply;
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name;     // Aidos Kuneen Wrapped ADK
    uint8 public decimals;  // 8
    string public symbol;   // ADK
    
    address public mainMeshOwner;  //the 'mesh owner', holds all token still inside the ADK Mesh (if not in circulation as wADK)
    address public statusAddress;  // is the request status admin, an address which can update user request stati.
    
    /* 
    ADK_DEPOSIT_ADDRESS_LIVE holds the most recent ADK MESH DEPOSIT ADDRESS. THIS IS THE ADK ADDRESS THAT MUST BE USED WHEN SENDING ADK to wADK (Ethereum)
    NOTE: THIS ADDRESS WILL CHANGE REGULARLY. ENSURE YOU ALWAYS USE THE LATEST ONE
    */
    
    string public ADK_DEPOSIT_ADDRESS_LIVE; 
                      
    /*
    ADK_DEPOSIT_ADDRESS_PREVIOUS is the PREVIOUS live address. ADK Deposits to this address will still be credited, BUT: Do not use this address for any new deposits. The purpose of keeping this address active is solely to capture any pending transactions at the time of address change.

    Note: Transfers to even older deposit addresses will still be ATTEMPTED to be credited by manually transferring them to a live address, but are at risk due to multi-spends (winternitz one-time signature).
    Long story short: Always!! use the latest ADK_DEPOSIT_ADDRESS_LIVE ADK address when sending ADK 
    */
    
    string public ADK_DEPOSIT_ADDRESS_PREVIOUS; 
                                                     
    uint256 public ADKDepositAddrCount; // Total number of historical ADK Mesh Contract deposit addresses
    
    mapping (uint256 => string) public ADKDepositAddrHistory; // holds the history of all ADK Mesh deposit addresses

    uint256 public requestID;    // counter / unique request ID 
    mapping (uint256 => string) public requestStatus; // Can be used to provide feedback to users re. status of their ADK/wADK requests.
    
    /*
    minimumADKforXChainTransfer: Indicates the minimum ADK or mADK required to transfer cross-chain.
    Note: value is in ADK Subunits, where 100000000 subADK = 1 ADK, i.e. 1.00000000 ADK
    */
    
    uint256 public minimumADKforXChainTransfer;  
    
    // CONSTRUCTOR
    constructor( // EIP20 Standard
        uint256 _initialAmount,
        string memory _tokenName,
        uint8  _decimalUnits,
        string memory _tokenSymbol
    ) {
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes (8 for ADK)
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        balances[msg.sender] = _initialAmount;               // Give the mesh address all initial tokens
        totalSupply = _initialAmount;                        // 2500000000000000 ADK in Mesh initially
        mainMeshOwner = msg.sender;                          // the address representing the ADK Mesh
        statusAddress = msg.sender;                          // initially also the owner
        requestID = 0; 
        ADKDepositAddrCount = 0;
        minimumADKforXChainTransfer = 10000000000;           // initially 100 ADK = 10000000000 units
    }

    // ERC20 events
    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    // Standard ERC20 transfer Function
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(address(this) != _to); // prevent accidental send of tokens to the contract itself! RTFM people!
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    // Standard ERC20 transferFrom Function
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 vallowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && vallowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (vallowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
    
    // Standard ERC20 approve Function
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    // Standard ERC20 balanceOf Function
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     // Standard ERC20 allowance Function
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    /// END DEFAULT ERC20 FUNCTIONS
    
    // MODIFIERS

    modifier onlyOwnerOrStatusAdmin {
        require(msg.sender == mainMeshOwner || msg.sender == statusAddress);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == mainMeshOwner);
        _;
    }
    
    /// BEGIN CUSTOM ADK FEATURES
    
    // ADM_setNewMinADKLimit: Sets the min-ADK X-Chain Transfer limit
    
    function ADM_setNewMinADKLimit(uint256 _newLimit) public onlyOwner {
        minimumADKforXChainTransfer = _newLimit;
    }

    // ADM_setNewStatusAdmin: Update the admin/Ethereum Address which is able to update user request status
    
    function ADM_setNewStatusAdmin(address _newAdmin) public onlyOwner {
        statusAddress = _newAdmin;
    }

    // ADM_setNewOwner: Change the owner/Ethereum Address which holds the Mesh Locked Token Balance
    
    function ADM_setNewOwner(address _newOwner) public onlyOwner {
        require(balances[_newOwner] == 0); // new mesh address cannot hold wADK already.
        mainMeshOwner = _newOwner;
        if ( balances[msg.sender] > 0 ) {
            transfer( _newOwner , balances[msg.sender] );
        }
    }
    
     // Custom EVENTS 
     
     event EvtTransferFromMesh(address _receiver, address _mesh_address, string _adk_address, uint256 _value);
     event EvtTransferToMesh(address _sender, address _mesh_address, string _adk_address, uint256 _value, uint256 _requestID, uint256 _fees);
     event EvtADKDepositAddressUpd(string ADK_DEPOSIT_ADDRESS_LIVE);
     event EvtStatusChanged(uint256 _requestID, string _oldStatus, string _newStatus);
    
    
    // Check if an address only contains 9A-Z, and is 81 or 90 char long
    
    modifier requireValidADKAddress (string memory _adk_address) {
        bool valid = true;
        bytes memory adkBytes = bytes (_adk_address);
        require(adkBytes.length == 81 || adkBytes.length == 90); //address with or without checksum
        
        for (uint i = 0; i < adkBytes.length; i++) {
            if ( 
                ! (
                    uint8(adkBytes[i]) == 57 //9
                     || (uint8(adkBytes[i]) >= 65 && uint8(adkBytes[i]) <= 90) //A-Z
                  )
               ) valid = false;
        }
        require (valid);
        _;
    } 
     
    /*  
    USR_transferToMesh: Called by users to request a transfer from wADK (Ethereum ERC20) back to ADK (Mesh)
    Note: This just calls the standard transfer function using the main Mesh Address, but logs also the target ADK address for processing.
    Note2: This function is PAYABLE as it will be possible to attach a fee to the transfer request in order to expedite the ADK mesh-release
    */
    
    function USR_transferToMesh(string memory _adk_address, uint256 _value) payable requireValidADKAddress (_adk_address) public {
        requestID += 1;
        require (_value >= minimumADKforXChainTransfer);
        transfer( mainMeshOwner , _value );
        requestStatus[requestID] = "RQ"; // transfer to mesh requested
        emit EvtTransferToMesh(msg.sender, mainMeshOwner, _adk_address, _value, requestID, msg.value);
    }
    
    
    // ADM_transferFromMesh: function invoked by the ADK Mesh Milestone Server (or delegate)  to unlock wADK and send wADK Token to the Ethereum address (specified by the user in the Smard Data field when depositing ADK for conversion)
    
    function ADM_transferFromMesh(address _receiver, uint256 _value, string memory _from_adk_address) public {
        // note _from_adk_address is for logging purpose only
        if (msg.sender == mainMeshOwner) { // if owner sends, then just use transfer 
            transfer( _receiver , _value );
        }
        else {
            transferFrom(mainMeshOwner, _receiver, _value); // otherwise use transferFrom (meaning the owner had to authorize the transfer first)
        }                                            // This will be used by custom helper contracts to pay multiple accounts etc
        
        emit EvtTransferFromMesh( _receiver, msg.sender, _from_adk_address, _value);
    }
    
    // ADM_updateMeshDepositAddress: Sets a new live ADK Mesh Deposit address, to be used for transfers from the Mesh to wADK  
    
    function ADM_updateMeshDepositAddress(string memory _new_deposit_adk_address) public 
                           onlyOwnerOrStatusAdmin requireValidADKAddress (_new_deposit_adk_address){
        
        ADK_DEPOSIT_ADDRESS_PREVIOUS = ADK_DEPOSIT_ADDRESS_LIVE; 
        ADK_DEPOSIT_ADDRESS_LIVE = _new_deposit_adk_address; 
        
        ADKDepositAddrCount += 1;
        ADKDepositAddrHistory[ADKDepositAddrCount] = _new_deposit_adk_address; // holds the history of all ADK Mesh deposit addresses
        
        emit EvtADKDepositAddressUpd(ADK_DEPOSIT_ADDRESS_LIVE);
    }
    
    // ADM_updateRequestStatus: allows a status admin to update request stati (feedback to users)  
    
    function ADM_updateRequestStatus(uint256 _requestID, string memory _status) public onlyOwnerOrStatusAdmin {
        string memory oldStatus = requestStatus[requestID];
        requestStatus[requestID] = _status;
        emit EvtStatusChanged(_requestID, oldStatus, _status);
    }

    /*
    USR_ETHAddrEncode and USR_ETHAddrDecode:
    Helper functions for en- and decoding of Eth Addresses as ADK compatible strings i.e. a 1:1 conversion from an Ethereum Address to an ADK compatible String, and vice versa

    USR_ETHAddrEncode: ENCODES/CONVERTS ETHEREUM ADDRESS to an ADK compatible String using only 9A-Z
    This is a PURE function (can be run without gas), and needs to be used by a user who wants to transfer ADK from the mesh to wADK. The 9AZ encoded eth address is included in the Mesh transaction to specify the target Ethereum Address that should receive the wADK
    */
    
    function USR_ETHAddrEncode(bytes memory ethAddr) public pure returns(string memory) {
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ9";
        require(ethAddr.length == 20); //20 bytes / an ethereum address 
    
        bytes memory str = new bytes(81);
        for (uint i = 0; i < 40; i++) {
            str[i*2+1] = alphabet[10+uint(uint8(ethAddr[i%20] & 0x0f))];  // add 10 to mix up the characters
            str[i*2] = alphabet[uint(uint8(ethAddr[i%20] >> 4))];  
        }
        str[80] = "9";
        return string(str);
    }
    
    /*
    USR_ETHAddrDecode: DECODES an ETHEREUM ADDRESS from an ADK compatible String only 9A-Z 
    (i.e. a 1:1 conversion from an ADK-Encoded Ethereum Address String to back an actual Ethereum Address)
    
    This is a PURE function (can be run without gas), and will be used by the Mesh Milestone Node to specify the target Ethereum Address that should receive the wADK
    */
    
    function USR_ETHAddrDecode(string memory adkString) public pure returns(address) {
        bytes memory str = new bytes(20); //2*40 hex char plus leading 0x
        bytes memory adkString_b = bytes(adkString);
        for (uint i = 0; i < 20; i++) {
            uint8 low = uint8(adkString_b[i*2+1])==57? 26 - 10 : uint8(adkString_b[i*2+1]) - 65 - 10;
            uint8 high = uint8(adkString_b[i*2])==57? 26 : uint8(adkString_b[i*2]) - 65;
            str[i] = bytes1(high * 16 + low); // Low Hex Char 
        }
        return utilBytesToAddress(str);
    }
    
    // utilBytesToAddress: Helper function to convert 20 bytes to a properly formated Ethereum address
    
    function utilBytesToAddress(bytes memory bys) private pure returns (address addr) {
        require(bys.length == 20);
        assembly {
          addr := mload(add(bys,20))
        } 
    }
    
    // ETH FEE COLLECTION FUNCTIONS:
    // The following functions are NOT related the ADK token, but are used to manage any ETH Fees,
    // that were sent to the contract address. It will cater for future features such as expedited 
    // processing (i.e. if the default processing time is too slow)
    
    event EvtReceivedGeneric(address, uint);
    event EvtReceivedFee(address, uint, string);
    
    // Fees sent to address where no _feeInfo string is required
    receive() external payable {
         emit EvtReceivedGeneric(msg.sender, msg.value);
    }
    
    // ADM_CollectFees: collect any ETH fees sent to the contract and forward to the specified address  for processing
    
    function ADM_CollectFees(address payable _collectToAddress, uint256 _value) onlyOwnerOrStatusAdmin public {
        _collectToAddress.transfer(_value); 
    }

    // USR_FeePayment: Allows users to pay fees for additional services, check main website/github for details
    
    function USR_FeePayment(string memory _feeInfo) payable public {
         emit EvtReceivedFee(msg.sender, msg.value, _feeInfo);
    }
    
    
}