/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;


contract ChainPass{
    address owner; //keeps track of the deployer of the smart contract
    
    modifier userFunc{//modifier to allow access only to registered users
       require(hasRegistered[msg.sender] == true);
        _;
    }
    
    modifier ownerFunc{//modifier to allow access only to contract deployer
        require(msg.sender == owner);
        _;
    }
    
    struct Account{//struct holding the accounts name and passwords
        string _accountname;
        string[3][] _passwords;
    }
    
    mapping(address => bool) private hasRegistered;//keeps track of who has registered
    mapping(address => Account) private _accounts;//keeps track of everyones account

	event Registered(address indexed _user);//emits upon a user registering
	
	constructor() public{
	    owner = msg.sender;
	}
    
    function register(address _user) public ownerFunc{//registeres a user, ownerfunc for now
        hasRegistered[_user] = true;
    	
    	emit Registered(_user);
    }
    
    function setName(string memory _name) public userFunc{//sets the desired name of the account
        _accounts[msg.sender]._accountname = _name;
    }
    
    function addPassword(string memory _url, string memory _username, string memory _password) public userFunc{//adds a password to the array
        _accounts[msg.sender]._passwords.push([_url, _username, _password]);
    }

    function deletePassword(uint _index) public userFunc{//deletes a password at a given index
        delete _accounts[msg.sender]._passwords[_index];
    }
    
    function checkIfRegistered() public view returns(bool){
        return hasRegistered[msg.sender];
    }
    
    function listPasswords() public userFunc view returns(string[3][] memory){
        return _accounts[msg.sender]._passwords;
    }
    
    function getName() public userFunc view returns(string memory){
        return _accounts[msg.sender]._accountname;
    }
    
    
}