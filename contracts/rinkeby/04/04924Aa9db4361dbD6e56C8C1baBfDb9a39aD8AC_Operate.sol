// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "Ownable.sol";

contract Operate is Ownable {

    // Variables

    uint256 bank_id_counter = 170106;
    uint256 user_id_counter = 17062;
    uint256 application_id_counter = 1062000;
    uint256 additional_doc_counter = 6756;

    // Arrays

    uint256[] public all_banks;
    string[] public universal_documents;
    uint256[] public additional_documents;

    // Mappings

    mapping(uint256 => Bank) public id_to_bank;
    mapping(uint256 => User) public id_to_user;
    mapping(uint256 => Application) public id_to_application;
    mapping(uint256 => AdditionalDoc) public id_to_addDoc;
    mapping(uint256 => mapping(address=>bool)) public bank_to_authorized_accounts;
    mapping(uint256 => mapping(string => string)) public user_to_document_links;
    mapping(uint256 => uint256[]) public user_to_all_applications;
    mapping(uint256 => uint256[]) public bank_to_pending_applications;
    mapping(uint256 => uint256[]) public bank_to_completed_applications;
    mapping(uint256 => mapping(uint256 => bool)) public addDoc_to_bank_voted;
    mapping(uint256 => uint256) public addDoc_to_positive_votes;
    mapping(uint256 => uint256) public addDoc_to_total_votes;

    // Structs

    struct Bank{
        uint256 bank_id;
        string name;
        string short_name;
        string logo_link;
    }

    struct User{
        uint256 user_id;
        address account_address;
        string first_name;
        string last_name;
        string email;
        uint256 phone_number;
        string gender;
        string age;
        string birth_date;
        string residential_address;
        string ip_address;
        string location_coordinates;
        string last_updated;
    }

    struct Application{
        uint256 application_id;
        uint256 user_id;
        uint256 bank_id;
        bool application_completed;
        uint256 bank_pending_index;
        string applied_on;
        address verified_by;
        string verified_on;
    }

    struct AdditionalDoc{
        uint256 addDoc_id;
        string doc_name;
        string doc_description;
        uint256 additional_docs_index;
    }


    // Events

    event Additions(
        string name,
        uint256 alloted_id
    );


    // Payable Functions

    function add_universal_documents(string[] memory _universal_documents) onlyOwner public{
        for (uint256 index = 0; index < _universal_documents.length; index++) {
            universal_documents.push(_universal_documents[index]);
        }
    }

    // Bank related

    function add_bank(string memory _bank_name, string memory _short_name, string memory _logo_link, address[] memory _authorized_accounts) onlyOwner public {
        Bank memory new_bank = Bank(
            bank_id_counter,
            _bank_name,
            _short_name,
            _logo_link
        );

        id_to_bank[bank_id_counter] = new_bank;
        all_banks.push(bank_id_counter);

        for (uint256 index = 0; index < _authorized_accounts.length; index++) {
            bank_to_authorized_accounts[bank_id_counter][_authorized_accounts[index]] = true;
        }

        emit Additions(_bank_name, bank_id_counter);

        bank_id_counter++;

    }
    

    function edit_bank(uint256 _bank_id, string memory _bank_name, string memory _logo_link, string memory _short_name) public{
        require(bank_to_authorized_accounts[_bank_id][msg.sender] == true, "User is not authorized to perform action");
        if(bytes(_bank_name).length != 0){
            id_to_bank[_bank_id].name = _bank_name;
        }
        
        if(bytes(_short_name).length != 0){
            id_to_bank[_bank_id].short_name = _short_name;
        }

        if(bytes(_logo_link).length != 0){
            id_to_bank[_bank_id].logo_link = _logo_link;
        }
    }


    function add_authorized_accounts(uint256 _bank_id, address[] memory _authorized_accounts) public{
        require(bank_to_authorized_accounts[_bank_id][msg.sender] == true, "User is not authorized to perform action");
        for (uint256 index = 0; index < _authorized_accounts.length; index++) {
            bank_to_authorized_accounts[_bank_id][_authorized_accounts[index]] = true;
        }
    }


    function suggest_additional_docs(uint256 _bank_id, string memory doc_name, string memory doc_description) public {
        require(bank_to_authorized_accounts[_bank_id][msg.sender] == true, "User is not authorized to perform action");
        
        AdditionalDoc memory new_doc = AdditionalDoc(
            additional_doc_counter,
            doc_name,
            doc_description,
            additional_documents.length
        );

        id_to_addDoc[additional_doc_counter] = new_doc;
        additional_documents.push(additional_doc_counter);
        
        // Vote from the adding bank
        addDoc_to_bank_voted[additional_doc_counter][_bank_id] = true;
        addDoc_to_positive_votes[additional_doc_counter]++;
        addDoc_to_total_votes[additional_doc_counter]++;

        additional_doc_counter++;
    }


    function cast_vote_addDoc(uint256 _bank_id, uint256 _addDoc_id, uint256 _vote_favor) public{
        require(bank_to_authorized_accounts[_bank_id][msg.sender] == true, "User is not authorized to perform action");
        require(addDoc_to_bank_voted[_addDoc_id][_bank_id] == false, "Already voted");
        
        addDoc_to_bank_voted[_addDoc_id][_bank_id] = true;

        if(_vote_favor == 1){
            addDoc_to_positive_votes[_addDoc_id]++;
            if(addDoc_to_positive_votes[_addDoc_id] > (all_banks.length / 2)){
                AdditionalDoc memory curr_doc = id_to_addDoc[_addDoc_id];
                if(additional_documents.length > 1){
                    additional_documents[curr_doc.additional_docs_index] = additional_documents[additional_documents.length-1];

                    id_to_addDoc[additional_documents[additional_documents.length-1]].additional_docs_index = curr_doc.additional_docs_index;
                }
                universal_documents.push(curr_doc.doc_name);
                additional_documents.pop();
            }
        }
        addDoc_to_total_votes[_addDoc_id]++;
    }


    function verify_application(uint256 _bank_id, uint256 _application_id, string memory _curr_date) public {
        require(bank_to_authorized_accounts[_bank_id][msg.sender] == true, "User is not authorized!");
        require(id_to_application[_application_id].application_completed == false, "Application already verified");

        id_to_application[_application_id].application_completed = true;
        id_to_application[_application_id].verified_by = msg.sender;
        id_to_application[_application_id].verified_on = _curr_date;

        uint256 _user_id = id_to_application[_application_id].user_id;

        bank_to_completed_applications[_bank_id].push(_application_id);

        //swap and update in bank completed

        if(bank_to_pending_applications[_bank_id].length > 1){
            
            // swap with last element
            bank_to_pending_applications[_bank_id][id_to_application[_application_id].bank_pending_index] = bank_to_pending_applications[_bank_id][bank_to_pending_applications[_bank_id].length-1];

            id_to_application[bank_to_pending_applications[_bank_id][bank_to_pending_applications[_bank_id].length-1]].bank_pending_index = id_to_application[_application_id].bank_pending_index;
        }

        bank_to_pending_applications[_bank_id].pop();

    }


    // User related

    function add_user(address _account_address, string[] memory _fname_lname, string memory _email, uint256 _phone_number, string[] memory _gen_age_birth, string memory _residential_address, string[] memory _document_names, string[] memory _document_links, string memory _ip_address, string memory _location_coordinates, string memory _curr_date) public onlyOwner{
        User memory new_user = User(
            user_id_counter,
            _account_address,
            _fname_lname[0],
            _fname_lname[1],
            _email,
            _phone_number,
            _gen_age_birth[0],
            _gen_age_birth[1],
            _gen_age_birth[2],
            _residential_address,
            _ip_address,
            _location_coordinates,
            _curr_date
        );

        id_to_user[user_id_counter] = new_user;

        for (uint256 index = 0; index < _document_names.length; index++) {
            user_to_document_links[user_id_counter][_document_names[index]] = _document_links[index];
        }

        emit Additions(_email, user_id_counter);

        user_id_counter++;
    }


    function add_update_user_documents(uint256 _user_id, string[] memory _document_names, string[] memory _document_links) public {
        require(msg.sender == id_to_user[_user_id].account_address, "User is not authorized!");

        for (uint256 index = 0; index < _document_names.length; index++) {
            user_to_document_links[_user_id][_document_names[index]] = _document_links[index];
        }
    }


    function edit_user(uint256 _user_id, address _account_address, string memory _fname, string memory _lname, uint256 _phone_number, string memory _birthdate, string memory _residential_address, string memory _ip_address, string memory _location_coordinates, string memory _curr_date) public{
        require(msg.sender == id_to_user[_user_id].account_address, "User is not authorized!");

        id_to_user[_user_id].account_address = _account_address;
        id_to_user[_user_id].first_name = _fname;
        id_to_user[_user_id].last_name = _lname;
        id_to_user[_user_id].phone_number = _phone_number;
        id_to_user[_user_id].birth_date = _birthdate;
        id_to_user[_user_id].residential_address = _residential_address;
        id_to_user[_user_id].ip_address = _ip_address;
        id_to_user[_user_id].location_coordinates = _location_coordinates;
        id_to_user[_user_id].last_updated = _curr_date;
    }


    function apply_to_bank(uint256 _user_id, uint256 _bank_id, string memory _curr_date) public returns(uint256){
        require(msg.sender == id_to_user[_user_id].account_address, "User is not authorized!");

        Application memory new_app = Application(
            application_id_counter,
            _user_id,
            _bank_id,
            false,
            bank_to_pending_applications[_bank_id].length,
            _curr_date,
            address(0),
            ""
        );

        id_to_application[application_id_counter] = new_app;
        user_to_all_applications[_user_id].push(application_id_counter);
        bank_to_pending_applications[_bank_id].push(application_id_counter);

        application_id_counter++;

        return application_id_counter-1;
    }


    // View functions

    function get_all_banks() public view returns(Bank[] memory){
        Bank[] memory banks = new Bank[](all_banks.length);
        for (uint256 index = 0; index < all_banks.length; index++) {
            banks[index] = id_to_bank[all_banks[index]];
        }
        return banks;
    }


    function user_all_applications(uint256 _user_id) public view returns(Application[] memory){
        Application[] memory pending_apps = new Application[](user_to_all_applications[_user_id].length);
        for (uint256 index = 0; index < user_to_all_applications[_user_id].length; index++) {
            pending_apps[index] = id_to_application[user_to_all_applications[_user_id][index]];
        }
        return pending_apps;
    }


    function bank_pending_applications(uint256 _bank_id) public view returns(Application[] memory){
        Application[] memory pending_apps = new Application[](bank_to_pending_applications[_bank_id].length);
        for (uint256 index = 0; index < bank_to_pending_applications[_bank_id].length; index++) {
            pending_apps[index] = id_to_application[bank_to_pending_applications[_bank_id][index]];
        }
        return pending_apps;
    }


    function bank_completed_applications(uint256 _bank_id) public view returns(Application[] memory){
        Application[] memory completed_apps = new Application[](bank_to_completed_applications[_bank_id].length);
        for (uint256 index = 0; index < bank_to_completed_applications[_bank_id].length; index++) {
            completed_apps[index] = id_to_application[bank_to_completed_applications[_bank_id][index]];
        }
        return completed_apps;
    }

    function get_universal_documents() public returns(string[] memory){
        return universal_documents;
    }

    function get_additional_docs(uint256 _bank_id) public returns(AdditionalDoc[] memory){
        AdditionalDoc[] memory all_additional_docs = new AdditionalDoc[](additional_documents.length);
        for (uint256 index = 0; index < additional_documents.length; index++) {
            if(addDoc_to_bank_voted[additional_documents[index]][_bank_id] == false){
                all_additional_docs[index] = id_to_addDoc[additional_documents[index]];
            }
        }
        return all_additional_docs;
    }

    function total_banks() public returns(uint256){
        return all_banks.length;
    }

    function vote_status(uint256 _addDoc_id) public returns(uint256[] memory){
        uint256[] memory votes = new uint256[](3);
        votes[0] = addDoc_to_positive_votes[_addDoc_id];
        votes[1] = addDoc_to_total_votes[_addDoc_id];
        votes[2] = all_banks.length;
        return votes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}