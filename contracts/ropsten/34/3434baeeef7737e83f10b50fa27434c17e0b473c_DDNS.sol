pragma solidity ^0.4.24;

contract DDNS {
    
    address public contractOwner;

    //Adds a structure called &quot;Domain&quot; which holds all domain name properties.
    struct Domain {
        string name;
        string IP;
        address owner;
        uint lockTime;
        string infoDocumentHash;
    }
    Domain private firstDomain; 
    //Adds the first empty domain to assure index 0 from DomainList will not be used later.
    
    //Domain private newDomain;
    
    mapping (string => uint) private DomainToIndex; 
    //Makes a mapping holding the registered domains mapped to an index from the array structure 
    //holding the domain details. Should start from 1 as 0 is default value for all names in the mapping.
    
    Domain[] public DomainList;
    //Creates a list(dynamic array) of registered ever domains (even locktime expired) 
    //which stores their structure details.
    
    constructor() public {
        contractOwner = msg.sender;
            
    //first empty domain will be assigned to 0 index of the DomainList and DomainToIndex mapping since 
    //by default all values are 0. Then during the if registered check the first domain added 
    //will give false if on index 0 is a valid domain.
            firstDomain.name = &quot;empty&quot;;
            firstDomain.IP = &quot;n/a&quot;;
            firstDomain.owner = 0;
            firstDomain.lockTime = 0;
            firstDomain.infoDocumentHash = &quot;n/a&quot;;
        
        DomainToIndex[firstDomain.name] = 0;
        DomainList.push(firstDomain);
    }
    
    //Since the shortest possible domain names are of 4 symbols the modifier checks if the name is less than that in length
    modifier StringLimit(string name) {
        bytes memory stringBytes = bytes(name);
        if(stringBytes.length < 4)
          revert(&quot;Error: Domain name too short.&quot;);
        _;
    }
    
    modifier OnlyContractOwner {
        require (msg.sender == contractOwner, &quot;Error: You are not the contract owner.&quot;);
        _;
    }

    modifier OnlyDomainOwner(string name) {
        require(DomainList[DomainToIndex[name]].owner == msg.sender, &quot;Error: You are not an owner of the domain.&quot;);
        require(DomainList[DomainToIndex[name]].lockTime > 0, &quot;Error: Your ownership of the domain has expired.&quot;);
        _;
    }
    
    event NewDomainRegisteredLog(string name, address owner, uint timeDuration);
    
    event DomainTransferLog(string name, address owner, uint timeDuration);
    
    function RegisterDomain(string name, string IP) payable public 
        StringLimit(name) {
        //Public method to register a domain, giving the domain name and an ip address it should point to. 
        //A registered domain cannot be bought and is owned by the caller of the method. The domain registration 
        //should cost 1 ETH and the domain should be registered for 1 year. After 1 year, anyone is allowed 
        //to buy the domain again. The domain registration can be extended by 1 year if the domain owner 
        //calls the register method and pays 1 ETH. The domain can be any string with length more than 5 symbols.
        
        require(msg.value >= 1 ether, &quot;Error: The domain name price is 1 ETH.&quot;);
        
        if(msg.sender == DomainList[DomainToIndex[name]].owner) {
            DomainList[DomainToIndex[name]].lockTime += 365 days;
			DomainList[DomainToIndex[name]].IP = IP;
        }
        else {
		    require(DomainList[DomainToIndex[name]].lockTime < now, &quot;Error: The domain is owned by someone else.&quot;);
            DomainToIndex[name] = DomainList.length;
            Domain memory newDomain;
                newDomain.name = name;
                newDomain.IP = IP;
                newDomain.owner = msg.sender;
                newDomain.lockTime = now + 365 days;
                newDomain.infoDocumentHash = &quot;Not Available&quot;;
            
            DomainList.push(newDomain);
        }
        
        if(msg.value > 1 ether) msg.sender.transfer(msg.value-1 ether);
        
        emit NewDomainRegisteredLog(name, DomainList[DomainToIndex[name]].owner, DomainList[DomainToIndex[name]].lockTime);
    } 

    function EditDomain(string name, string IP) public
        OnlyDomainOwner(name) {
        //Public method to edit a domain. Editing a domain is changing the ip address it points to. 
        //The operation is free. Only the owner of the domain can edit the domain.
        
        DomainList[DomainToIndex[name]].IP = IP;
    }
    
    function TransferDomain(string name, address newOwner) public
        OnlyDomainOwner(name) {
        //Public method to transfer the domain ownership to another user. The operation is free.
        
        DomainList[DomainToIndex[name]].owner = newOwner;
        
        emit DomainTransferLog(name, newOwner, DomainList[DomainToIndex[name]].lockTime);
    }
    
    function AddDomainInfoDocument(string name, string hash) public 
        OnlyDomainOwner(name) {
            DomainList[DomainToIndex[name]].infoDocumentHash = hash;
    }
    
    function GetDomainInfo(string name) view public 
        StringLimit(name) 
        returns(string, string, address, uint, string) {
        //Public view method to receive all propoerties of a given domain.
        
        uint index = DomainToIndex[name];
        
        return (DomainList[index].name, DomainList[index].IP, DomainList[index].owner, 
        DomainList[index].lockTime,DomainList[index].infoDocumentHash);
    }
    
    function ContractOwnerWithdraw(uint amount) public 
        OnlyContractOwner {
            require(amount > 0 && amount < address(this).balance, &quot;Error: Required value is bigger than existing amount.&quot;);
            msg.sender.transfer(amount);
    }
    
    function GetContractBalance() view public 
        OnlyContractOwner 
        returns(uint) {
            return address(this).balance;
    }
    
}