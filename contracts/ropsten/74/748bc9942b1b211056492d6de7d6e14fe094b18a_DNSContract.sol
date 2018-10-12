pragma solidity ^0.4.20;

/**
 * 
 * @author Fady Aro 01-10-2018
 * 
 * DDNS Smart Contract
 *
 * A Decentralized Domain Name Server
 * 
 * Giving more meaning for the blockchain
 * 
 * Host Unstoppable Domains
 */
 
 contract usingDNSTools {

    /**
     * internal domain name validation
     *  
     * domain name contains only numbers, alphabets and &#39;-&#39; character
     * 
     * returns 0x0 on failure
     * 
     * returns lower case domain name on success
     */
    function validate(bytes32 name) internal pure returns (bytes32) {
        bytes32 arr;
        uint blank = 0;
        for(uint i = 0; i < 32; i++) {
            if(name[i] >= 65 && name[i] <= 90) {
                if(blank == 1) 
                    return 0x0;
                arr |= bytes32(bytes1(uint(name[i]) + 32) & 0xFF) >> (i * 8);
            } else if((name[i] >= 97 && name[i] <= 122) 
                || name[i] == 45
                || (name[i] >= 48 && name[i] <= 57)) {
                if(blank == 1) 
                    return 0x0;
                arr |= bytes32((name[i]) & 0xFF) >> (i * 8);
            } else if(name[i] == 32 || name[i] == 0x0) {
                blank = 1;
                arr |= bytes32(0x0 & 0xFF) >> (i * 8);
            } else {
                return 0x0;
            }
        }
        return arr;
    }
}

contract DNSContract is usingDNSTools {
    
    event DomainRegistered(address holder, bytes32 domain);
    
    struct record {
        
        address holder;
        
        string connector;
        
        string rawHtml;
        
    }
    
    uint constant REGISTRATION_PRICE_WEI = 10**15;
    
    address owner;
    
    mapping(bytes32 => record) sites;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function register(bytes32 _domain, string _connector, string _rawHtml) public payable {
        
        bytes32 _site = validate(_domain);
        
        require
        (
            msg.value > REGISTRATION_PRICE_WEI
            && _site != 0x00
            && sites[_site].holder == 0x00
        );
        
        sites[_site].holder = msg.sender;
        sites[_site].connector = _connector;
        sites[_site].rawHtml = _rawHtml;
        
        owner.transfer(msg.value);
        
        emit DomainRegistered(msg.sender, _site);
    }
    
    function domainHtml(bytes32 _domain) public view returns(string) {
        return sites[_domain].rawHtml;
    }
    
    function domainConnector(bytes32 _domain) public view returns(string) {
        return sites[_domain].connector;
    }
}