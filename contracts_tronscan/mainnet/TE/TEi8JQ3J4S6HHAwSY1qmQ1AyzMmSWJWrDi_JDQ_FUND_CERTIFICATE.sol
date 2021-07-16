//SourceUnit: JDQ_FUND_CERTIFICATE.sol

pragma solidity >=0.4.22 <0.6.0;


contract JDQ_FUND_CERTIFICATE {
    
    address owner;
    
    struct Counter{
        uint256 amount;
        uint64 times;
    }
    
    mapping(address => Counter) public countOf;

    constructor() public {
        owner = msg.sender;
    }
    
    function addCertificate(address holder, uint256 amount, bytes sn) public returns(bool success){
        require(msg.sender == owner, 'permission denied');
        require(sn.length <= 64, 'sn should less than 64 bytes');
        countOf[holder].amount +=  amount;
        countOf[holder].times += 1;
        return true;
    }
}