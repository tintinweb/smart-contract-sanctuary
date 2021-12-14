pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

interface RegularsNFTContract {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface RegularsERC20Contract {
    function mint(address to, uint256 amount) external;
}

contract Companies {

    uint private version = 2;

    // address for Regulars erc721 contract
    address private regularsNFT_Address = 0x6d0de90CDc47047982238fcF69944555D27Ecb25;
    address private regularsERC20_Address = 0x84e7122440CB41935749a926be1DC96E2C4A5AA2; //V3

    // Company
    struct Company {
        uint[] members; // IDs of the NFT Collection (Regulars)
        string name; // QUESTION -- String or Bytes32?
        string productName; // The employees will make a "product" as NFT
        bytes ipfsHash; // offchain data
    }

    Company[] public companies;
    mapping(uint => uint) private companyIDs;

    // Job Offer
    mapping(uint => uint[] ) private offers;

    // track timestamps when companies are created, grow or shrink in size
    struct companyEvent {
        uint size;
        uint timestamp;
    }
    mapping(uint => companyEvent[]) companyEvents;

    // Payments
    Paycenter paycenter;
    mapping(uint => uint) lastPayments; // timestamps of payments for each NFT ID (not wallet addresses)
    // uint constant PAY_DURATION = 1 weeks; 
    uint constant PAY_DURATION = 1 days; 

    // Events
    event CreatedCompany(uint[] members, string companyName);
    event LeftCompany(uint member, string companyName);
    event JoinedCompany(uint[] members, string companyName);
    event CreateOffer(uint members, uint[] candidate, string companyName);
    event AcceptOffer(uint member, string companyName);
    event ClaimAll(address member, uint amount);

    constructor() {
        // initialize companies with empty company.. so we can test (companies[..] =! 0) to know if a NFT is in a company
        Company memory _company;
        _company.name = "NO COMPANY";
        companies.push(_company);  
        paycenter = new Paycenter();
    }

    // Create Company
    function createCompany(string memory _companyName, uint[] memory _members) public {
        // require(ownsNFTs(_members), "You don't own these NFT.");
        require(!inAnyCompany(_members), "Already in a company. Must leave first.");
        Company memory _company;
        _company.name = _companyName; // should we make sure this is unique?
        companies.push(_company);  
        companies[companies.length - 1].members = _members; 

        // iterate over all founding members
        for (uint i = 0; i < _members.length; i++){
            // map all the members to the ID of the company
            companyIDs[_members[i]] = uint16(companies.length) - 1; 
            // initiliaze 'last payments' to time of company creation, for each member
            lastPayments[_members[i]] = block.timestamp;
        }

        //init company history
        companyEvent memory ce = companyEvent ({  
            size:  _members.length,
            timestamp : block.timestamp
        });
        companyEvents[uint16(companies.length)].push(ce);

        emit CreatedCompany(_members, _companyName);
    }

    // log timestamps of changes in company member count
    function addCompanyEvent(uint _companyID) private {
        companyEvent memory ce = companyEvent ({ 
            size:  companies[_companyID].members.length,
            timestamp : block.timestamp
        });
        companyEvents[_companyID].push(ce);
    }

    // This is only called internally -- rename to join company?
    function joinCompany(uint _companyID, uint[] memory _newMembers) private {
        for (uint i; i < _newMembers.length;i++) {
            companies[_companyID].members.push(_newMembers[i]);
            companyIDs[_newMembers[i]] = _companyID;

            // initiliaze 'last payments' to time of company creation, for each member
            lastPayments[_newMembers[i]] = block.timestamp;
        }
        addCompanyEvent(_companyID);
        emit JoinedCompany(_newMembers, companies[_companyID].name);
    }

    // Leave Company
    function leaveCompany(uint[] memory _members, uint _companyID) public {
        require(ownsNFTs(_members), "You don't own these NFTs.");
        require(inAnyCompany(_members),"Not in a company.");
        Company memory _company = companies[_companyID];
        
        for (uint m = 0; m < _members.length; m++) {
            for (uint i = 0; i < _company.members.length; i++) {
                if (_company.members[i] == _members[m]) {
                    delete companies[_companyID].members[m];
                    companyIDs[_members[m]] = 0; 
                    emit LeftCompany(_members[m], _company.name);
                    break;
                }
            }
        }
        // When anyone leaves a company, we claim all unclaimed $REG 
        // (for all NFTs owned by wallet?)
        claimAll(msg.sender);
        addCompanyEvent(_companyID);
    }

    // Job Offers
    function createJobOffer(uint _member, uint _companyID, uint[] memory _candidates) public  { 
        require(ownsNFT(_member), "You don't own this NFT."); // would be nice to convert this to an arraydw
        require(companyIDs[_member] == _companyID, "Does not belong to company.");

        // for each job candidate
        for (uint i = 0; i < _candidates.length; i++){
             // if wallet owns both NFTs, they can join the company with no offer
            if (ownerOfNFT(_member) == ownerOfNFT(_candidates[i])){ 
                uint [] memory c = new uint[](1); 
                c[0] = (_candidates[i]);
                joinCompany( _companyID, c);
            } else {
                offers[_candidates[i]].push(_companyID);
                emit CreateOffer(_member, _candidates, companies[_companyID].name);
            }
        }
    }

    function acceptJobOffer(uint _companyID, uint[] memory _members) public {
       require(ownsNFTs(_members), "Does not own NFT(s).");

       for (uint m = 0; m < _members.length; m++) {
            uint[] memory _offers = offers[_members[m]];
            for (uint i = 0; i < _offers.length ; i++) {

                uint [] memory _m = new uint[](1); 
                _m[0] = _members[m];

                if (_offers[i] ==_companyID){ 
                    // If candidate belongs to a company, leave the company first... 
                    if (companyIDs[_members[m]] != 0)  {
                        leaveCompany(_m,companyIDs[_members[m]]);
                    }
                    joinCompany( _companyID, _m);
                    delete offers[_members[m]];
                    emit AcceptOffer(_members[m], companies[companyIDs[_members[m]]].name);
                    // break; // <---- DO I NEED THIS ?
                }
            }
       }
    }

// view functions

    function getCompanyIdByEmployeeID(uint _member) public view returns(uint){
        return companyIDs[_member];
    }

    // function getCompanyName(uint _member) public view returns(string memory){
    //     return companies[companyIDs[_member]].name;
    // }

    function contractVersion() public view returns(uint){
        return version;
    }

// we might be able to delete this -- if we can find a way to convert a single uint into a one-element array in one line.

    function ownsNFT(uint _NFTid) private view returns (bool) {
        return ownerOfNFT(_NFTid) == msg.sender; 
    }

    function ownsNFTs(uint[] memory _NFTids) private view returns (bool){
        for (uint i = 0; i<_NFTids.length; i++) {
            if (ownerOfNFT(_NFTids[i]) == msg.sender)
                return false;
        }
        return true;
    }

    function inAnyCompany(uint[] memory _NFTids) private view returns (bool){
        for (uint i = 0; i<_NFTids.length; i++) {
            if (companyIDs[_NFTids[i]] != 0) 
                return true; // the nft IS in a company
        }
        return false; // the nft is NOT in a company
    }

    function allNFTIndexes(address _address) public view returns(uint[] memory){
        uint[] memory nfts = new uint[](balanceOfNFTs(_address));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = tokenOfOwnerByIndex(_address, i);
        }
        return nfts;
    }


// Proxy Methods

    function ownerOfNFT(uint _tokenId) private view returns (address) {
        return RegularsNFTContract(regularsNFT_Address).ownerOf(_tokenId);
    }

    function balanceOfNFTs(address _address) private view returns (uint) {
        return RegularsNFTContract(regularsNFT_Address).balanceOf(_address);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) private view returns (uint256) {
        return RegularsNFTContract(regularsNFT_Address).tokenOfOwnerByIndex(_owner,_index);
    }

// Payments

     // returns pay rate for a specific employee
    function currentSalary(uint _member) public view returns (uint) {
        require(companyIDs[_member] != 0, "Not in a company");
        uint companySize = companies[companyIDs[_member]].members.length;
        uint i = 0;
        for (i; i < companySize; i++){
            if (companies[companyIDs[_member]].members[i] == _member){
                break;
            }
        }
        return paycenter.payRate(i, companySize);
    }

    function unclaimed(uint _member) public view returns (uint) {
        // between last paid and now... cycle through all company events, calculate the payrate for each segment of time and add it up.
        uint _unclaimed = 0;
        bool started = false;
        uint lower; // lower bounds of time segment
        uint upper; // upper bounds of time segment
        uint startTime = lastPayments[_member];
        uint companyID = companyIDs[_member];
        uint companySize = companies[companyID].members.length;
        uint numHire;

        //calculate numHire
        for (uint m = 0; m < companies[companyID].members.length; m++){
            if (companies[companyID].members[m] == _member){
                numHire = m;
                break;
            }
        }

        // iterate over all company events (change of company size) and calc salary amounts
        for (uint i = 0; i < companyEvents[companyID].length; i++){
            lower = companyEvents[companyID][i].timestamp;
            upper = companyEvents[companyID][i+1].timestamp;
            if (startTime >= lower && startTime <= upper){
                started = true;
                lower = startTime;
            }
            if (started){
                uint segmentDuration = upper - lower;
                _unclaimed += paycenter.payRate(numHire, companySize) * segmentDuration / PAY_DURATION;
            }
        }
        return(_unclaimed);
    }

    function unclaimedAll(address _address) public view returns (uint){
        uint totalPay = 0;
        uint[] memory _members = allNFTIndexes(_address);
        for (uint i = 0; i < _members.length; i++){
            totalPay += unclaimed(_members[i]);
        }
        return totalPay;
    }

    function claimAll(address _address) public returns (uint){
        uint totalPay = 0;
        uint[] memory _members = allNFTIndexes(_address);
        for (uint i = 0; i < _members.length; i++){
            totalPay += unclaimed(_members[i]);
            lastPayments[_members[i]] = block.timestamp;
        }
        RegularsERC20Contract(regularsERC20_Address).mint(_address, totalPay);
        emit ClaimAll(_address, totalPay);
        return totalPay;
    }

}

contract Paycenter {

    uint constant BASEPAY = 1000000; // 1000 $REG
    int constant  COMPANY_SIZE_BONUS_FACTOR = 30; // factor for bonus amount
    int constant  EARLY_HIRE_BONUS_FACTOR = 12; // factor for bonus amount
    uint constant PRECISION = 100; // 

    constructor() {
    }

    // Returns pay for given company size + hire number
    function payRate(uint _hireNum, uint _companySize) public pure returns (uint) {
        // poor-man's log function
        int myLog = int(myLogarithm(_companySize));
        // company size bonus as a percentage
        int companySizeBonus = myLog * COMPANY_SIZE_BONUS_FACTOR / int(PRECISION); // %
        int salary = (int(BASEPAY) * companySizeBonus + 100000) / int(PRECISION); // Salary + companySizeBonus
        // hire number bonus.. earlier hires earn more
        int delta = myLog * EARLY_HIRE_BONUS_FACTOR * int(PRECISION);
        int hireBonus = (int(_hireNum) - (int(_companySize) / 2)) * -1 * delta / int(_companySize) / int(PRECISION);
        // calculate final salary
        salary = salary + salary * hireBonus / int(PRECISION**2);
        return uint(salary);
    }

    function myLogarithm(uint _count) private pure returns (uint) {
        uint i;
        for (i = 1; i < 12; i++) {  // Max count = 2^12
            if (2**i > _count)
                break;
        }
        return  (PRECISION * (i - 1) + (_count - 2**(i - 1)) * PRECISION / 2**(i-1));
    }
}