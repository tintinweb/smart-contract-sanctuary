/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

contract Lapid {

    struct _extracontact {
        uint index;
        string contact;
        string conatcttype;
        string isVerified;
        string status;
    }

    struct _extraaddress {
        uint index;
        string addresstype;
        string addressDetails;
    }

    struct _document {
        uint index;
        string documenttype;
        string documentDetails;
    }

    struct _transaction {
        uint index;
        string transactionDetails;
    }

    address[] _allUsers;

    mapping(address => string) _userList;
    mapping(address => _extracontact[]) _userContacts;
    mapping(address => _extraaddress[]) _userAddresses;
    mapping(address => _document[]) _userDocuments;
    mapping(address => _transaction[]) _userTransactions;

    /** @dev Add User into `_allUsers` array.
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `_userDetails` cannot be the null.
     */
    function addUser(address _userAddress, string memory _userDetails) public returns (string memory){
        _userList[_userAddress] = _userDetails;
        _allUsers.push(_userAddress);
        return 'success';
    }

    /** @dev Update User by user address.
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `_userDetails` and `_userAddress` cannot be the null.
     */
    function updateUser(address _userAddress, string memory _userDetails) public returns (string memory){
        _userList[_userAddress] = _userDetails;
        return 'success';
    }

    /** @dev Fetch User by user address.
     *
     * Return a `allUsers` object of user details
     *
     * Requirements
     *
     *  `_userAddress` cannot be the null.
     */
    function fetchUser(address _userAddress) public view returns (string memory){
        string memory allUsers = _userList[_userAddress];
        return allUsers;
    }

    /** @dev Fetch All User .
     *
     * Return a `allUsers` object of user details
     *
     */
    function fetchAllUser() public view returns (address[] memory){
        return _allUsers;
    }

    /** @dev Add User Contact into `_userContacts` on key `_userAddress`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `contact`,`contacttype`,`isVerified`,`status` cannot be the null.
     */
    function addContact(address _userAddress, string memory contact, string memory contacttype, string memory isVerified, string memory status) public returns (string memory){
        uint contactListLength = _userContacts[_userAddress].length;
        _extracontact memory test = _extracontact(contactListLength + 1, contact, contacttype, isVerified, status);
        _userContacts[_userAddress].push(test);
        return 'success';
    }

    /** @dev update User Contact into `_userContacts` on key `_userAddress`,`index`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `isVerified`,`status`,`index` cannot be the null.
     */
    function updateContact(address _userAddress, string memory contact, string memory isVerified, string memory status, uint index) public returns (string memory){
        _userContacts[_userAddress][index - 1].contact = contact;
        _userContacts[_userAddress][index - 1].status = status;
        _userContacts[_userAddress][index - 1].isVerified = isVerified;
        return 'success';
    }

    /** @dev Fetch User Contact by user address.
     *
     * Return a `allContact` object of user contact details
     *
     * Requirements
     *
     *  `_userAddress` cannot be the null.
     */
    function fetchUserContacts(address _userAddress) public view returns (_extracontact[] memory){
        _extracontact[] memory allContact = _userContacts[_userAddress];
        return allContact;
    }

    /** @dev Add User Contact into `_userAddresses` on key `_userAddress` and `index`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `addresstype`,`line1`,`line2`,`line3`,`pincode`,`city`,`state`,`country` cannot be the null.
     */
    function addAddress(address _userAddress, string memory addresstype, string memory details) public returns (string memory){
        uint addressListLength = _userAddresses[_userAddress].length;
        _extraaddress memory test = _extraaddress(addressListLength + 1, addresstype, details);
        _userAddresses[_userAddress].push(test);
        return 'success';
    }

    /** @dev update User Address into `_userContacts` on key `_userAddress` and `index`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `addresstype`,`line1`,`line2`,`line3`,`pincode`,`city`,`state`,`country`,`index` cannot be the null.
     */

    function updateAddress(address _userAddress, string memory addresstype, string memory details, uint index) public returns (string memory){
        _userAddresses[_userAddress][index - 1].addresstype = addresstype;
        _userAddresses[_userAddress][index - 1].addressDetails = details;
        return 'success';
    }

    /** @dev Fetch User Address by user address.
     *
     * Return a `allAddress` object of user address details
     *
     * Requirements
     *
     *  `_userAddress` cannot be the null.
     */
    function fetchUserAddresses(address _userAddress) public view returns (_extraaddress[] memory){
        _extraaddress[] memory allAddress = _userAddresses[_userAddress];
        return allAddress;
    }

    /** @dev Add User Document into `_userDocuments` on key `_userAddress` and `index`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `documenttype`,`details` cannot be the null.
     */
    function addDocument(address _userAddress, string memory documenttype, string memory details) public returns (string memory){
        uint documentListLength = _userDocuments[_userAddress].length;
        _document memory test = _document(documentListLength + 1, documenttype, details);
        _userDocuments[_userAddress].push(test);
        return 'success';
    }

    /** @dev Update User Document into `_userDocuments` on key `_userAddress` and `index`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  status` cannot be the null.
     */
    function updateDocument(address _userAddress, string memory documenttype, string memory details, uint index) public returns (string memory){
        _userDocuments[_userAddress][index - 1].documenttype = documenttype;
        _userDocuments[_userAddress][index - 1].documentDetails = details;
        return 'success';
    }

    /** @dev Fetch User Address by `_userAddress`.
     *
     * Return a `allDocuments` object of user address details
     *
     * Requirements
     *
     *  `documenttype`,`details` cannot be the null.
     */
    function fetchUserDocuments(address _userAddress) public view returns (_document[] memory){
        _document[] memory allDocuments = _userDocuments[_userAddress];
        return allDocuments;
    }
    /** @dev Add Transaction into `_userTransactions` on key `_userAddress` and `index`
     *
     * Return a message of successfull
     *
     * Requirements
     *
     *  `details` cannot be the null.
     */
    function addTransaction(address _userAddress, string memory details) public returns (string memory){
        uint txnListLength = _userTransactions[_userAddress].length;
        _transaction memory test = _transaction(txnListLength + 1, details);
        _userTransactions[_userAddress].push(test);
        return 'success';
    }

    /** @dev Fetch User Transaction by `_userAddress`.
     *
     * Return a `allTransactions` object of user transaction details
     *
     * Requirements
     *
     *  `_userAddress` cannot be the null.
     */
    function fetchTransaction(address _userAddress) public view returns (_transaction[] memory){
        _transaction[] memory allTransactions = _userTransactions[_userAddress];
        return allTransactions;
    }
}