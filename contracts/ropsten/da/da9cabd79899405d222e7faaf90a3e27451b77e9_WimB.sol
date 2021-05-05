/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity >0.5.0;

/*
DISCLAIMER: This contract is clearly not optimized in terms of computational complexity. It's meant to be kept short and concise.
            It can be improved by replacing all arrays with mappings (which are basically hashmaps) so as to reduce time complexity.
            However take in mind that mappings consider all keys exist and so always return a default value if the given key has never been assigned a value.
*/

contract WimB {

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed sender, address indexed to, uint tokens);
    event PersonRemoval(address indexed removed, address indexed attachedTo, Role indexed role);
    event HolderAdd(address indexed added);
    
    uint256 _totalSupply;
    mapping(address => uint256) _balances; //mapping of accounts and their balances
    mapping(address => mapping(address => uint256)) _allowed; //mapping of accounts allowed to withdraw from a given account and their balances
    address[] _holders; //all token holders
    address[] _appointees; //who have right to transfer their representee's token to another account 
    address _owner;
    
    enum Role {Holder, Appointee, Owner}
    
    constructor() public payable {
        _totalSupply = 1000000;
        //_holders = new address[](100);
        _holders.push(msg.sender);
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        
    }

    /*Total token amount at creation time
    */
    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns(uint){
        return _balances[tokenOwner];
    }
    
    /*Total withdrawal amount by appointee cannot exceed allowance.
    Allowance remains unchanged until the holder change it.
    */
    function allowance(address tokenOwner, address appointee) public view returns(uint){
        return _allowed[tokenOwner][appointee];
    }
    
    function transfer(address to, uint transferAmount) public payable returns(bool){
        transferFrom(msg.sender, to, transferAmount);
        return true;
    }
    
    function transferFrom(address provenance, address receiver, uint transferAmount) public payable returns (bool){
        require(holderExist(provenance), "Debitor is not a holder.");
        require(holderExist(receiver), "Receiver is not a holder. Please add new account before transfering tokens to this account.");
        require(_balances[provenance] >= transferAmount, "Balance not enough");
        if(msg.sender != provenance){
            require(_allowed[provenance][msg.sender] >= transferAmount, "Not enough tokens authorized");
        }
        _balances[provenance] = _balances[provenance] - transferAmount;
        _balances[receiver] = _balances[receiver] + transferAmount;
        
        emit Transfer(provenance, receiver, transferAmount);
        return true;
    }
    
    function approve(address appointee, uint withdrawAmount) public payable returns (bool){
        require(checkHolderPermission(msg.sender), "Account not authorized");
        require(_balances[msg.sender] >= withdrawAmount, "Balance not enough");
        _allowed[msg.sender][appointee] = withdrawAmount;
        emit Approval(msg.sender, appointee, withdrawAmount);
        return true;
    }

    function holderExist(address accountToCheck) public view returns (bool){
        for(uint i = 0; i<_holders.length; i++){
            if(_holders[i] == accountToCheck)
                return true;
        }
        return false;
    }

    function addHolder(address accountToAdd) public returns (bool){
        require(!holderExist(accountToAdd), "Holder already exists.");
        require(checkHolderPermission(msg.sender), "Not authorized");
        _holders.push(accountToAdd);
        assert(holderExist(accountToAdd));
        
        emit HolderAdd(accountToAdd);
        return true;
    }

    /*Only contract's owner can remove a holder.
    */
    function removeHolder(address toRemove) public returns (bool){
        require(checkOwnerPermission(msg.sender), "Not authorized.");
        require(holderExist(toRemove), "Holder not exist.");
        require(_balances[toRemove] == 0, "Balance is not 0, please transder all credit to another account before remove. ");
        uint index;
        for(uint i = 0; i<_holders.length; i++){
            if(_holders[i] == toRemove){
                index = i;
            }
        }
        uint256 arrlen = _holders.length;
        delete _holders[index];
        _holders[index] = _holders[arrlen - 1];
        //_holders.length--;
        
        emit PersonRemoval(toRemove, address(0), Role.Holder);
        return true;
    }

    /*Only appointee's holder can remove him.
    */
    function removeAppointee(address toRemove) public returns (bool){
        require(checkHolderPermission(msg.sender), "Not authorized as a holder or owner of contract.");
        require(_allowed[msg.sender][toRemove] != 0, "Not authorized to remove appointee.");
        _allowed[msg.sender][toRemove] = 0;
        
        emit PersonRemoval(toRemove, msg.sender, Role.Appointee);
        return true;
    }

    function checkHolderPermission(address toCheck) public view returns (bool){
        return (holderExist(toCheck));
    }
    
    function checkOwnerPermission(address toCheck) public view returns (bool){
        return (toCheck == _owner);
    }
    
    function checkAppointeePermission(address toCheck, address mapToOwner) public view returns (bool){
        return (_allowed[mapToOwner][toCheck] != 0);
    }

    function getOwner() public view returns(address owner){
        return _owner;
    }
}