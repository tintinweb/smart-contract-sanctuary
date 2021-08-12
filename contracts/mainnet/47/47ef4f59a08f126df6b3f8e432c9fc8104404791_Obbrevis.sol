/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

//SPDX-License-Identifier: Obbvrevis Ware

/** 
 * This code/file/software is owned by Obbrevis and Obrevis only.
 * All rights belong to Obbrevis.
 * Only Obbrevis authorizes the use of this code.
 * 
**/

pragma solidity 0.8.4;

/** 
 * @title Obbrevis Core 
 * @dev Maps an address to username
 * 
**/
 
contract Obbrevis {
    
    struct State {
        bool isInitialized; // If Contract is initialized and used to power on or off the app
        address ownerAddress; // owner
        address selfAddress; // address of contract
        uint256 verificationFees; // Verification Fees in WEI
        uint256 maxArrayBuffer; // Max length of an array
        uint256 maxPageBuffer;
        string version;
    }
    
    struct AddressUsernamePair {
        address useraddress;
        bytes32 username;
        bool isVerified;
    }
    
    struct User {
        bool init;
        address useraddress; // User Address
        bytes32 username;  // Username
        bool isVerified; // If user is verified
    }
    
    address ownerAddress;
    address selfAddress;
    mapping(address => User) addressToUser;
    mapping(bytes32 => address) usernameToAddress;
    mapping(address => bool) authorizedUsers;
    address[] mappedAddresses;
    mapping(bytes32 => bool) blockedUsernames;
    State contractState;
    
    
    
    constructor(uint256 _verificationFees) {
        ownerAddress = msg.sender;
        authorizedUsers[msg.sender] = true;
        contractState =  State({
            isInitialized: false,
            ownerAddress: ownerAddress,
            selfAddress: address(0),
            verificationFees: _verificationFees,
            maxArrayBuffer: 1000,
            maxPageBuffer: 1000,
            version: "1.0.0"
        });
    }
    
    // Utils
    
    function _validateUsername(bytes32 _username) private pure returns(bool) {
        uint8 stringLength = 1;
        uint8 i = 1;
        
        // Checking is the first character is a letter [a-z]
        if(_username[0] >= 0x61 && _username[0] <= 0x7a) {
            
            // Starting form the second character.
            for(i = 1; i < 32; i++) {
                
                // Check the length of the string.
                if(_username[i] == 0x00) {
                    if(stringLength < 3) return false;
                    else return true;
                }
                
                // Check if the second+ characters are [a-z][0-9][_]
                if(!(_username[i] >= 0x61 && _username[i] <= 0x7a)) {
                   if(!(_username[i] >= 0x30 && _username[i] <= 0x39)) {
                       if(_username[i] != 0x5f) return false;
                   }
                }
                
                // Increment counter.
                stringLength++;
            }
        }
        
        return false;
    }
    
    function _withdrawETHToOwner(uint256 _amount) private returns(bool) {
         payable(ownerAddress).transfer(_amount);
         return true;
    }
    
    function _checkExistingPairFromAddress(address _address) private view returns(bool) {
        bytes32 savedUsername = addressToUser[_address].username;
        address savedAddress = usernameToAddress[savedUsername];
        
        if(_address == savedAddress) return true;
        return false;
    }
    
    function _checkExistingPairFromUsername(bytes32 _username) private view returns(bool) {
        address savedAddress = usernameToAddress[_username];
        bytes32 savedUsername = addressToUser[savedAddress].username;
        
        if(savedUsername == _username) return true;
        return false;
    }
    
    function _checkExistingPair(address _address, bytes32 _username) private view returns(bool) {
        if(_checkExistingPairFromAddress(_address) && _checkExistingPairFromUsername(_username)) {
            bytes32 savedUsername = addressToUser[_address].username;
            address savedAddress = usernameToAddress[_username];
            return ((savedUsername == _username) && (savedAddress == _address));
        }
        
        return false;
    }
    
    function _checkUsername(bytes32 _username) private view returns(bool) {
        
        // Check if username is blocked.
        if(blockedUsernames[_username]) return false;
        
        // Check if the username is used.
        if(usernameToAddress[_username] == address(0)) return true;
        return false;
    }
    
    function _mapAddress(address _address, bytes32 _username, bool _verified) private returns(User memory) {
        require(_validateUsername(_username), "Error 400: Invalid Username.");
        require(_checkUsername(_username), "Error 500: Username is taken.");
        
        // Check if address has an old user object.
        User memory oldUser = addressToUser[_address];
        
        /**
         *  If User object is initialised?
         *  TRUE: Free the old username to Address mapping.
         *  FALSE: Meaning the user is fresh so increament address Counter
         **/
        if(oldUser.init == true) {
            usernameToAddress[oldUser.username] = address(0);
            addressToUser[_address].username = _username;
            usernameToAddress[_username] = _address;
        } else {
            addressToUser[_address] = User({
                init: true,
                useraddress: _address,
                username: _username,
                isVerified: _verified
            });
            usernameToAddress[_username] = _address;
            mappedAddresses.push(_address);
        }
        
        return addressToUser[_address];
    }
    
    
    // External Functions
    
    function mapAddress(bytes32 _username) external returns(User memory) {
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(contractState.isInitialized, "Error 503: Contract not Initialized.");
        
        return _mapAddress(msg.sender, _username, false);
    }
    
    function verify(bytes32 _username) external payable returns(User memory) {
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(msg.value >= contractState.verificationFees, "Error 400: Insufficient Verification Fees.");
        require(contractState.isInitialized, "Error 503: Contract not Initialized.");
        require(_checkExistingPair(msg.sender, _username), "Error 500: Invalid Address-Username Pair.");
        require(!addressToUser[msg.sender].isVerified, "Error 500: User is already verified.");
        
        _withdrawETHToOwner(msg.value);
        addressToUser[msg.sender].isVerified = true;
        return addressToUser[msg.sender];
    }
    
    
    // Getters and Setters
    
    function getAddress(bytes32 _username) external view returns(address) {
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(_checkExistingPairFromUsername(_username), "Error 500: Username! Invalid Address-Username Pair.");
        
        return usernameToAddress[_username];
    }
    
    function getUser(address _address) external view returns(User memory) {
        require(_address != address(0), "Error 400: Invalid Address");
        require(_checkExistingPairFromAddress(_address), "Error 500: Address! Invalid Address-Username Pair.");
        
        return addressToUser[_address];
    }
    
    function getUserByUsername(bytes32 _username) external view returns(User memory) {
        require(_username != bytes32(0), "Error 400! Invalid Username");
        require(_checkExistingPairFromUsername(_username), "Error 500: Username! Invalid Address-Username Pair.");
        
        return addressToUser[usernameToAddress[_username]];
    }
    
    function getUsernamesByAddresses(address[] calldata _addresses) external view returns(AddressUsernamePair[] memory) {
        require(_addresses.length <= contractState.maxArrayBuffer, "Error 400: Too many input");
        
        uint256 i;
        AddressUsernamePair[] memory res = new AddressUsernamePair[](_addresses.length);
        for(i=0; i<_addresses.length; i++) {
            res[i].useraddress = _addresses[i];
            
            User memory tempUser = addressToUser[_addresses[i]];
            
            if(tempUser.init) {
                res[i].username = tempUser.username;
                 res[i].isVerified = tempUser.isVerified;
            } else  res[i].username = bytes32(0);
        }
        
        return res;
    }
    
    function getAddressesByUsernames(bytes32[] calldata _usernames) external view returns(AddressUsernamePair[] memory) {
        require(_usernames.length <= contractState.maxArrayBuffer, "Error 400: Too many input");
        
        uint256 i;
        AddressUsernamePair[] memory res = new AddressUsernamePair[](_usernames.length);
        for(i = 0; i < _usernames.length; i++) {
            res[i].username = _usernames[i];
            
            address tempAddress = usernameToAddress[_usernames[i]];
            
            if(tempAddress != address(0)) {
                User memory tempUser = addressToUser[tempAddress];
                
                if(tempUser.init) {
                    res[i].useraddress = tempUser.useraddress;
                    res[i].username = tempUser.username;
                    res[i].isVerified = tempUser.isVerified;
                } else  res[i].username = bytes32(0);
            } else res[i].useraddress = address(0);
        }
        
        return res;
    }
    
    function getNumberOfAddress() external view returns(uint256) {

        return mappedAddresses.length;
    }
    
    function validateUsername(bytes32 _username) external pure returns(bool) {
        require(_username != bytes32(0), "Error 400: Invalid Username");
        
        return _validateUsername(_username);
    }
    
    function checkUsername(bytes32 _username) external view returns(bool) {
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(contractState.isInitialized, "Error 503: Contract not Initialized.");
        
        return _checkUsername(_username);
    }
    
    function getCurrentState() external view returns(State memory) {
        
        return contractState;
    }
    
    function isAuthorizedUser(address _address) external view returns(bool) {
        require(_address != address(0), "Error 400: Invalid Address");
        
        return authorizedUsers[_address];
    }
    
    // Owner and Authorized Methods
    
    /** 
    * Initialize method to initialize the contract.
    * 
    **/
    function power(bool _power) external returns(State memory) {
        require(msg.sender == ownerAddress, "Error 401: Unauthorized Access.");
        
        contractState.isInitialized = _power;
        return contractState;
    }
    
    function initialize(bytes32 _ownerUsername, address _selfAddress, bytes32 _selfUsername) external returns(bool) {
        require(msg.sender == ownerAddress, "Error 401: Unauthorized Access.");
        require(_ownerUsername != bytes32(0), "Error 400: Invalid Owner Username");
        require(_selfAddress != address(0), "Error 400: Invalid Self Address");
        require(_selfUsername != bytes32(0), "Error 400: Invalid Self Username");
        
        selfAddress = _selfAddress;
        contractState.selfAddress = selfAddress;
        
        // Manually map owner address
        _mapAddress(ownerAddress, _ownerUsername, true);
        _mapAddress(_selfAddress, _selfUsername, true);
        
        contractState.isInitialized = true;
        return true;
    }
    
    function authoriseUser(address _address, bool _state) external returns(bool) {
        require(msg.sender == ownerAddress, "Error 401: Unauthorized Access.");
        require(contractState.isInitialized, "Error 503: Contract not Initialized.");
        
        authorizedUsers[_address] = _state;
        return authorizedUsers[_address];
    }
    
    function withdrawETHToOwner(uint256 _amount) external returns(bool) {
        require(msg.sender == ownerAddress, "Error 401: Unauthorized Access.");
        require(_amount > 0, "Error 400: Invalid Amount! Amount must be greater than 0.");
        
        return _withdrawETHToOwner(_amount);
    }
    
    // Before Blocking a Username, first check with _checkUsername() if the username is used, blocked or not.
    function blockUsername(bytes32 _blockUsername, bytes32 _newUsername) external returns(bool) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_blockUsername != bytes32(0), "Error 400: Invalid Username");
        require(_newUsername != bytes32(0) && _newUsername != _blockUsername, "Error 400: Invalid Username");
        
        // Check if the username is free else map the current holder to another username
        if(!_checkUsername(_blockUsername)) {
            
            // Check if address has an old user object.
            address currentAddress = usernameToAddress[_blockUsername];
            _mapAddress(currentAddress, _newUsername, false);
        }
        
        blockedUsernames[_blockUsername] = true;
        return true;
    }
    
    function unblockUsername(bytes32 _blockedUsername) external returns(bool) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_blockedUsername != bytes32(0), "Error 400: Invalid Username");
        
        blockedUsernames[_blockedUsername] = false;
        return true;
    }
    
    function usernameSwap(address _fromAddress, bytes32 _fromUsername, address _toAddress, bytes32 _toUsername)
    external returns(User memory, User memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_fromAddress != address(0), "Error 400: Invalid Address");
        require(_toAddress != address(0), "Error 400: Invalid Address");
        require(_fromUsername != bytes32(0), "Error 400: Invalid Username");
        require(_toUsername != bytes32(0), "Error 400: Invalid Username");
        require(contractState.isInitialized, "Error 503: Contract not Initialized.");
        require(_checkExistingPair(_fromAddress, _fromUsername), "Error 500: Invalid From Address-Username Pair.");
        require(_checkExistingPair(_toAddress, _toUsername), "Error 500: Invalid To Address-Username Pair.");
        
        addressToUser[_fromAddress].username = _toUsername;
        addressToUser[_toAddress].username = _fromUsername;
        
        usernameToAddress[_fromUsername] = _toAddress;
        usernameToAddress[_toUsername] = _fromAddress;
        
        return(addressToUser[_fromAddress], addressToUser[_toAddress]);
    }
    
    function getMappedAddresses(uint256 _page) external view returns(address[] memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_page >= 1, "Error 400: Invalid Page Number.");
        
        uint256 i;
        uint256 j = 0;
        address[] memory res;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 tempUpperLimit = _page * contractState.maxPageBuffer;
        
        if(mappedAddresses.length < tempUpperLimit) {
            if(mappedAddresses.length < contractState.maxPageBuffer) lowerLimit = 0;
            else lowerLimit = (_page - 1) * contractState.maxPageBuffer;
            
            upperLimit = mappedAddresses.length;
            
            // If an unvailable page is requested lowerLimit will be greater than upperLimit
            if(lowerLimit > upperLimit) return res;
            
            // If lowerLimit == 0, then you should requesting for only page 1
            if(lowerLimit == 0 && _page > 1) return res;
        } else {
            lowerLimit = (_page - 1) * contractState.maxPageBuffer;
            upperLimit = tempUpperLimit;
        }
        
        uint256 resLength = upperLimit - lowerLimit;
        res = new address[](resLength);

        for(i = lowerLimit; i < upperLimit; i++) {
            res[j] = mappedAddresses[i];
            j++;
        }
        
        return res;
    }
    
    function authorizedMapAddress(address _address, bytes32 _username, bool _isVerified) external returns(User memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(contractState.isInitialized, "Error 503: Contract not Initialized.");
        
        return _mapAddress(_address, _username, _isVerified);
    }
    
    function authorizedVerify(address _address, bytes32 _username) external returns(User memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_address != address(0), "Error 400: Invalid Address");
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(_checkExistingPair(_address, _username), "Error 500: Invalid Address-Username Pair.");
        
        addressToUser[_address].isVerified = true;
        return addressToUser[_address];
    }
    
    function unVerify(address _address, bytes32 _username) external returns(User memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        require(_address != address(0), "Error 400: Invalid Address");
        require(_username != bytes32(0), "Error 400: Invalid Username");
        require(_checkExistingPair(_address, _username), "Error 500: Invalid Address-Username Pair.");
        
        addressToUser[_address].isVerified = false;
        return addressToUser[_address];
    }
    
    function setVerificationFees(uint256 _verificationFees) external returns(State memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        
        contractState.verificationFees = _verificationFees;
        return contractState;
    }
    
    function setMaxBuffer(uint256 _maxArrayBuffer, uint256 _maxPageBuffer) external returns(State memory) {
        require(authorizedUsers[msg.sender], "Error 401: Unauthorized Access.");
        
        if(_maxArrayBuffer > 0) contractState.maxArrayBuffer = _maxArrayBuffer;
        if(_maxPageBuffer > 0) contractState.maxPageBuffer = _maxPageBuffer;
        
        return contractState;
    }
}