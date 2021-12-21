pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface RegularsNFTContract {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface RegularsERC20Contract {
    function mint(address to, uint256 amount) external;
}

contract Companies {
    using EnumerableSet for EnumerableSet.UintSet;

    uint private version = 7;
    uint constant BASEPAY = 1000000;
    uint constant DECIMALS = 10000000000000000;
    uint constant PAY_DURATION = 100 seconds; // sped up for testing

    // address for Regulars erc721 contract
    address private regularsNFT_Address = 0x6d0de90CDc47047982238fcF69944555D27Ecb25;
    address private regularsERC20_Address = 0x84e7122440CB41935749a926be1DC96E2C4A5AA2; //V3

    // Company
    struct Company {
        string name; // QUESTION -- String or Bytes32?
        uint[] members; // Ids of the NFTs (Regulars)
        string productName; // The employees will make a "product" as NFT
        bytes ipfsHash; // offchain data
    }

    Company[] public companies;
    mapping(uint => uint) private companyIDs; // map member IDs to companyIDs

    // Job Offer
    mapping(uint => uint[] ) private offers; // map member IDs to array of companyIDs

    // track timestamps when companies are created, grow or shrink in size
    struct companyEvent {
        uint size;
        uint timestamp;
    }
    mapping(uint => companyEvent[]) private companyEvents;

    // Payments
    Paycenter paycenter;
    mapping(uint => uint) lastPayments; // timestamps of payments for each NFT ID (not wallet addresses)

    // Events
    event CreatedCompany(uint[] members, string companyName, uint companyID);
    event LeftCompany(uint member, string companyName);
    event JoinedCompany(uint[] members, string companyName);
    event CreateOffer(uint members, uint[] candidate, string companyName);
    event AcceptOffer(uint member, string companyName);
    event ClaimAll(address member, uint amount);
    event LOG(string message, uint number);


    constructor() {
        // initialize companies with empty company.. so we can check (companies[..] =! 0) to know if a NFT is in a company
        Company memory _company;
        _company.name = "NO COMPANY";
        companies.push(_company);  
        paycenter = new Paycenter(BASEPAY);

// dummy data for testing
        uint [] memory myMembers = new uint[](4);
        myMembers[0] = 61;
        myMembers[1] = 6179;
        myMembers[2] = 6112;
        myMembers[3] = 64;
        createCompany("McDonalds", myMembers);

        uint [] memory myMembers2 = new uint[](6);
        myMembers2[0] = 4;
        myMembers2[1] = 5;
        myMembers2[2] = 6;
        myMembers2[3] = 7;
        myMembers2[4] = 8;
        myMembers2[5] = 9;
        createCompany("Burger King", myMembers2);

        uint [] memory myMembers3 = new uint[](3);
        myMembers3[0] = 5464;
        myMembers3[1] = 4551;
        myMembers3[2] = 9445;
        createCompany("Ionels Company LLC", myMembers3);
    }

// Create Company
    function createCompany(string memory _companyName, uint[] memory _members) public {
        // require(ownsNFTs(_members), "You don't own these NFT.");
        require(!inAnyCompany(_members), "Already in a company. Must leave first.");
        Company memory _company;
        _company.name = _companyName; // should we make sure this is unique?
        companies.push(_company);  
        uint _companyID = companies.length - 1;
        companies[_companyID].members = _members; // PROBLEM

        for (uint i = 0; i < _members.length; i++){
            companyIDs[_members[i]] = uint16(_companyID); 
            lastPayments[_members[i]] = block.timestamp;
        }
        addCompanyEvent(_companyID);
        emit CreatedCompany(_members, _companyName, _companyID);
    }

    // log timestamps of changes in company member count
    function addCompanyEvent(uint _companyID) private {
        companyEvent memory ce = companyEvent ({ 
            size:  companies[_companyID].members.length, // PROBLEM
            timestamp : block.timestamp
        });
        companyEvents[_companyID].push(ce);
    }

    function joinCompany(uint _companyID, uint[] memory _newMembers) private {
        for (uint i; i < _newMembers.length;i++) {
            companies[_companyID].members.push(_newMembers[i]);  // PROBLEM
            companyIDs[_newMembers[i]] = _companyID;
            lastPayments[_newMembers[i]] = block.timestamp; // initiliaze 'last payments' to time of joining
        }
        addCompanyEvent(_companyID);
        emit JoinedCompany(_newMembers, companies[_companyID].name);
    }

    // Leave Company
    function leaveCompany(uint[] memory _members) public {
        // require(ownsNFTs(_members), "You don't own these NFTs."); // ADD BACK IN    

        // must be in same company
        uint _companyID = companyIDs[_members[0]];
        for (uint i = 0; i < _members.length; i++) {
            if (companyIDs[_members[i]] != _companyID) 
                revert("members not in same company.");
        }

        for (uint i = 0; i < _members.length; i++) { // iterate through all members to delete
            for (uint j = 0; j < companies[_companyID].members.length; j++) { // iterate through all members of company
                if (_members[i] == companies[_companyID].members[j]) {
                    delete companies[_companyID].members[j];
                    companyIDs[_companyID] = 0; 
                    emit LeftCompany(_members[i], companies[_companyID].name);
                    break;
                }
                }
            }
            // When anyone leaves a company, we claim all unclaimed $REG 
        // claimAll();  // ADD BACK IN  
        addCompanyEvent(_companyID);
    }

// Job Offers
    function createJobOffer(uint _member, uint _companyID, uint[] memory _candidates) public  { 
        require(ownerOfNFT(_member) == msg.sender, "You don't own this NFT."); 
        require(companyIDs[_member] == _companyID, "Does not belong to company.");
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

            for (uint i = 0; i < offers[_members[m]].length ; i++) {

                if (offers[_members[m]][i] ==_companyID){ 
                    uint [] memory _m = new uint[](1); 
                    _m[0] = _members[m];
                    // If candidate belongs to a company, leave the company first... 
                    if (companyIDs[_members[m]] != 0)  {
                        leaveCompany(_m);
                    }
                    joinCompany( _companyID, _m);
                    delete offers[_members[m]];
                    emit AcceptOffer(_members[m], companies[companyIDs[_members[m]]].name);
                    break; 
                }
            }
       }
    }

// view functions

    function getCompanyMembersByID(uint _companyID) public view returns(uint[] memory){
        return companies[_companyID].members;
    }

    function getCompanyIdByMemberID(uint _member) public view returns(uint){
        return companyIDs[_member];
    }

    function getCompanyName(uint _member) public view returns(string memory){
        return companies[companyIDs[_member]].name;
    }

    function contractVersion() public view returns(uint){
        return version;
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

    function inAnyCompany(uint _NFTid) private view returns (bool){
        if (companyIDs[_NFTid] != 0) 
            return true; // the nft IS in a company
        return false; // the nft is NOT in a company
    }

    function allNFTsByAddress(address _address) public view returns(uint[] memory){ // CHANGE BACK TO PUBLIC
        uint[] memory nfts = new uint[](balanceOfNFTs(_address));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = tokenOfOwnerByIndex(_address, i);
        }
        return nfts;
    }

    function numHireByID(uint _member) private view returns (uint){
        uint [] memory arr = new uint[](1); 
        arr[0] = (_member);
        require(inAnyCompany(arr),"not in company");
        uint numHire = 0;
        for (uint m = 0; m < companies[companyIDs[_member]].members.length; m++){
            if (companies[companyIDs[_member]].members[m] == _member){
                numHire = uint(m);
                break;
            }
        }
        return numHire;
    }

    function getJobOffers(uint _memberID) public view returns (uint[] memory){
        return offers[_memberID];
    }

    function getCompaniesByRange(uint _start, uint _end) public view returns (Company[] memory) {
        if (_end < companies.length)
            _end = companies.length - 1;
        Company[] memory _companies = new Company[](_end - _start);
        for (uint i = 0; i < _companies.length;i++){
            _companies[i] = companies[i];
        }
        return _companies;
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

    function companyEventsLengthByID(uint _companyID) public view returns (string memory,uint) {
        return (companies[_companyID].name, companyEvents[_companyID].length);
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
        uint numHire = numHireByID(_member);

        // iterate over all company events (change of company size) and calc salary amounts
        for (uint i = 0; i < companyEvents[companyID].length; i++){
            lower = companyEvents[companyID][i].timestamp;
            if (i + 1 < companyEvents[companyID].length)
                upper = companyEvents[companyID][i+1].timestamp; 
            else
                upper = block.timestamp; // if we are at the end, change upper to current time
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

    function unclaimedAll(address _address) public view returns (uint){ // CHANGE BACK TO VIEW
        uint totalPay = 0;
        uint[] memory _members = allNFTsByAddress(_address);
        for (uint i = 0; i < _members.length; i++){
            if (companyIDs[_members[i]] != 0) // member is in a company
                totalPay += unclaimed(_members[i]);
        }
        return totalPay;
    }

    function claimAll() public returns (uint){
        uint totalPay = 0;
        uint[] memory _members = allNFTsByAddress(msg.sender);
        for (uint i = 0; i < _members.length; i++){
            if (inAnyCompany(_members[i])) {// member is in a company
                totalPay += unclaimed(_members[i]);
                lastPayments[_members[i]] = block.timestamp;
            }
        }
        RegularsERC20Contract(regularsERC20_Address).mint(msg.sender, totalPay);
        emit ClaimAll(msg.sender, totalPay);
        return totalPay * DECIMALS;
    }

    function totalInCompanyByAddress() public view returns (uint,uint) {
        uint result = 0;
        uint[] memory _members = allNFTsByAddress(msg.sender);
        for (uint i = 0; i < _members.length; i++){
            if (inAnyCompany(_members[i])) // member is in a company
                result++;
        }
        return (_members.length,result);
    }

}

contract Paycenter {

    uint private basepay;
    int constant  COMPANY_SIZE_BONUS_FACTOR = 30; // factor for bonus amount
    int constant  EARLY_HIRE_BONUS_FACTOR = 12; // factor for bonus amount
    uint constant PRECISION = 100; // 

    constructor(uint _basepay) {
        basepay = _basepay;
    }

    // Returns pay for given company size + hire number
    function payRate(uint _hireNum, uint _companySize) public view returns (uint) {
        // poor-man's log function
        int myLog = int(myLogarithm(_companySize));
        // company size bonus as a percentage
        int companySizeBonus = myLog * COMPANY_SIZE_BONUS_FACTOR / int(PRECISION); // %
        int salary = (int(basepay) * companySizeBonus + 100000) / int(PRECISION); // Salary + companySizeBonus
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}