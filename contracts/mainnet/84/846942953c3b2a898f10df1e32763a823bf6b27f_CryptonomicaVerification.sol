pragma solidity ^0.4.19;

/*
developed by cryptonomica.net, 2018
last version: 2018-02-18
github: https://github.com/Cryptonomica/
*/

contract CryptonomicaVerification {

    /* ---------------------- Verification Data */

    // Ethereum address is connected to OpenPGP public key data from Cryptonomica.net
    // Ethereum address can be connected to one OpenPGP key only, and one time only
    // If OpenPGP key expires, user have to use another Ethereum address for new OpenPGP public key
    // But user can verify multiple Ethereum accounts with the same OpenPGP key

    // ---- mappings to store verification data, to make it accessible for other smart contracts
    // we store sting data as bytes32 (http://solidity.readthedocs.io/en/develop/types.html#fixed-size-byte-arrays)
    // !!! -> up to 32 ASCII letters,
    // see: https://ethereum.stackexchange.com/questions/6729/how-many-letters-can-bytes32-keep

    // OpenPGP Message Format https://tools.ietf.org/html/rfc4880#section-12.2 : "A V4 fingerprint is the 160-bit SHA-1 hash ..."
    // thus fingerprint is 20 bytes, in hexadecimal 40 symbols string representation
    // fingerprints are stored as upper case strings like:
    // 57A5FEE5A34D563B4B85ADF3CE369FD9E77173E5
    // or as bytes20: "0x57A5FEE5A34D563B4B85ADF3CE369FD9E77173E5" from web3.js or Bytes20 from web3j
    // see: https://crypto.stackexchange.com/questions/32087/how-to-generate-fingerprint-for-pgp-public-key
    mapping(address => bytes20) public fingerprint; // ..............................................................0

    // we use unverifiedFingerprintAsString to store fingerprint provided by user
    mapping(address => string) public unverifiedFingerprint; // (!) Gas requirement: infinite

    mapping(address => uint) public keyCertificateValidUntil; // unix time ..........................................1
    mapping(address => bytes32) public firstName; // ................................................................2
    mapping(address => bytes32) public lastName; // .................................................................3
    mapping(address => uint) public birthDate; // unix time .........................................................4
    // Nationality - from user passport or id document:
    // 2-letter country codes defined in ISO 3166
    // like returned by Locale.getISOCountries() in Java (upper case)
    // see: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
    mapping(address => bytes32) public nationality; //      .........................................................5
    mapping(address => uint256) public verificationAddedOn; // unix time ............................................6
    mapping(address => uint256) public revokedOn; // unix time, returns uint256: 0 if verification is not revoked ...7
    // this will be longer than 32 char, and have to be properly formatted (with "\n")
    mapping(address => string) public signedString; //.(!) Gas requirement: infinite.................................8

    // unix time online converter: https://www.epochconverter.com
    // for coders: http://www.convert-unix-time.com
    mapping(address => uint256) public signedStringUploadedOnUnixTime;

    // this allows to search for account connected to fingerprint
    // as a key we use fingerprint as bytes32, like 0x57A5FEE5A34D563B4B85ADF3CE369FD9E77173E5
    mapping(bytes20 => address) public addressAttached; //

    // (!) Gas requirement: infinite
    string public stringToSignExample = "I hereby confirm that the address <address lowercase> is my Ethereum address";

    /* the same data as above stored as a struct:
    struct will be returned as &#39;List&#39; in web3j (only one function call needed) */
    mapping(address => Verification) public verification; // (!) Gas requirement: infinite
    struct Verification {
        // all string have to be <= 32 chars
        string fingerprint; // ................................................0
        uint keyCertificateValidUntil; // .....................................1
        string firstName; // ..................................................2
        string lastName;// ....................................................3
        uint birthDate; //  ...................................................4
        string nationality; //  ...............................................5
        uint verificationAddedOn;// ...........................................6
        uint revokedOn; // ....................................................7
        string signedString; //................................................8
        // uint256 signedStringUploadedOnUnixTime; //... Stack too deep
    }

    /*  -------------------- Administrative Data */
    address public owner; // smart contract owner (super admin)
    mapping(address => bool) public isManager; // list of managers

    uint public priceForVerificationInWei; // see converter on https://etherconverter.online/

    address public withdrawalAddress; // address to send Ether from this contract
    bool public withdrawalAddressFixed = false; // this can be smart contract with manages ETH from this SC

    /* --------------------- Constructor */
    function CryptonomicaVerification() public {// Constructor must be public or internal
        owner = msg.sender;
        isManager[msg.sender] = true;
        withdrawalAddress = msg.sender;
    }

    /* -------------------- Utility functions : ---------------------- */

    // (?) CryptonomicaVerification.stringToBytes32(string memory) : Is constant but potentially should not be.
    // probably because of &#39;using low-level calls&#39; or &#39;using inline assembly that contains certain opcodes&#39;
    // but &#39;The compiler does not enforce yet that a pure method is not reading from the state.&#39;
    // > in fact works as constant
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {// (!) Gas requirement: infinite
        // require(bytes(source).length <= 32); // causes error, but string have to be max 32 chars

        // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
        // http://solidity.readthedocs.io/en/latest/assembly.html
        // this converts every char to its byte representation
        // see hex codes on http://www.asciitable.com/ (7 > 37, a > 61, z > 7a)
        // "az7" > 0x617a370000000000000000000000000000000000000000000000000000000000
        assembly {
            result := mload(add(source, 32))
        }
    }

    // see also:
    // https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    // https://ethereum.stackexchange.com/questions/1081/how-to-concatenate-a-bytes32-array-to-a-string
    // 0x617a370000000000000000000000000000000000000000000000000000000000 > "az7"
    function bytes32ToString(bytes32 _bytes32) public pure returns (string){// (!) Gas requirement: infinite
        // string memory str = string(_bytes32);
        // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
        // thus we should convert bytes32 to bytes (to dynamically-sized byte array)
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /* -------------------- Verification functions : ---------------------- */

    // from user acc
    // (!) Gas requirement: infinite
    function uploadSignedString(string _fingerprint, bytes20 _fingerprintBytes20, string _signedString) public payable {

        // check length of the uploaded string,
        // it expected to be a 64 chars string signed with OpenPGP standard signature
        // bytes: Dynamically-sized byte array,
        // see: http://solidity.readthedocs.io/en/develop/types.html#dynamically-sized-byte-array
        // if (bytes(_signedString).length > 1000) {//
        //    revert();
        //    // (payable)
        // }
        // --- not needed: if string is to big -> out of gas

        // check payment :
        if (msg.value < priceForVerificationInWei) {
            revert();
            // (payable)
        }

        // if signed string already uploaded, should revert
        if (signedStringUploadedOnUnixTime[msg.sender] != 0) {
            revert();
            // (payable)
        }

        // fingerprint should be uppercase 40 symbols
        if (bytes(_fingerprint).length != 40) {
            revert();
            // (payable)
        }

        // fingerprint can be connected to one eth address only
        if (addressAttached[_fingerprintBytes20] != 0) {
            revert();
            // (payable)
        }

        // at this stage we can not be sure that key with this fingerprint really owned by user
        // thus we store it as &#39;unverified&#39;
        unverifiedFingerprint[msg.sender] = _fingerprint;

        signedString[msg.sender] = verification[msg.sender].signedString = _signedString;

        // uint256 - Unix Time
        signedStringUploadedOnUnixTime[msg.sender] = block.timestamp;

        SignedStringUploaded(msg.sender, _fingerprint, _signedString);

    }

    event SignedStringUploaded(address indexed fromAccount, string fingerprint, string uploadedString);

    // from &#39;manager&#39; account only
    // (!) Gas requirement: infinite
    function addVerificationData(
        address _acc, //
        string _fingerprint, // "57A5FEE5A34D563B4B85ADF3CE369FD9E77173E5"
        bytes20 _fingerprintBytes20, // "0x57A5FEE5A34D563B4B85ADF3CE369FD9E77173E5"
        uint _keyCertificateValidUntil, //
        string _firstName, //
        string _lastName, //
        uint _birthDate, //
        string _nationality) public {

        // (!!!) only manager can add verification data
        require(isManager[msg.sender]);

        // check input
        // fingerprint should be uppercase 40 symbols
        // require(bytes(_fingerprint).length == 40);
        // require(bytes(_firstName).length <= 32);
        // require(bytes(_lastName).length <= 32);
        // _nationality should be like "IL" or "US"
        // require(bytes(_nationality).length == 2);
        // >>> if we control manager account we can make checks before sending data to smart contract (cheaper)

        // check if signed string uploaded
        require(signedStringUploadedOnUnixTime[_acc] != 0);
        // to make possible adding verification only one time:
        require(verificationAddedOn[_acc] == 0);

        verification[_acc].fingerprint = _fingerprint;
        fingerprint[_acc] = _fingerprintBytes20;

        addressAttached[_fingerprintBytes20] = _acc;

        verification[_acc].keyCertificateValidUntil = keyCertificateValidUntil[_acc] = _keyCertificateValidUntil;
        verification[_acc].firstName = _firstName;
        firstName[_acc] = stringToBytes32(_firstName);
        verification[_acc].lastName = _lastName;
        lastName[_acc] = stringToBytes32(_lastName);
        verification[_acc].birthDate = birthDate[_acc] = _birthDate;
        verification[_acc].nationality = _nationality;
        nationality[_acc] = stringToBytes32(_nationality);
        verification[_acc].verificationAddedOn = verificationAddedOn[_acc] = block.timestamp;

        VerificationAdded(
            verification[_acc].fingerprint,
            _acc,
        // keyCertificateValidUntil[_acc],
        // verification[_acc].firstName,
        // verification[_acc].lastName,
        // birthDate[_acc],
        // verification[_acc].nationality,
            msg.sender
        );
        // return true;
    }

    event VerificationAdded (
        string forFingerprint,
        address indexed verifiedAccount, // (1) indexed
    // uint keyCertificateValidUntilUnixTime,
    // string userFirstName,
    // string userLastName,
    // uint userBirthDate,
    // string userNationality,
        address verificationAddedByAccount
    );

    // from user or &#39;manager&#39; account
    function revokeVerification(address _acc) public {// (!) Gas requirement: infinite
        require(msg.sender == _acc || isManager[msg.sender]);

        verification[_acc].revokedOn = revokedOn[_acc] = block.timestamp;

        // event
        VerificationRevoked(
            _acc,
            verification[_acc].fingerprint,
            block.timestamp,
            msg.sender
        );
    }

    event VerificationRevoked (
        address indexed revocedforAccount, // (1) indexed
        string withFingerprint,
        uint revokedOnUnixTime,
        address indexed revokedBy // (2) indexed
    );

    /* -------------------- Administrative functions : ---------------------- */

    // to avoid mistakes: owner (super admin) should be changed in two steps
    // change is valid when accepted from new owner address
    address private newOwner;
    // only owner
    function changeOwnerStart(address _newOwner) public {
        require(msg.sender == owner);
        newOwner = _newOwner;
        ChangeOwnerStarted(msg.sender, _newOwner);
    } //
    event ChangeOwnerStarted (address indexed startedBy, address indexed newOwner);
    // only by new owner
    function changeOwnerAccept() public {
        require(msg.sender == newOwner);
        // event here:
        OwnerChanged(owner, newOwner);
        owner = newOwner;
    } //
    event OwnerChanged(address indexed from, address indexed to);

    // only owner
    function addManager(address _acc) public {
        require(msg.sender == owner);
        isManager[_acc] = true;
        ManagerAdded(_acc, msg.sender);
    } //
    event ManagerAdded (address indexed added, address indexed addedBy);
    // only owner
    function removeManager(address manager) public {
        require(msg.sender == owner);
        isManager[manager] = false;
        ManagerRemoved(manager, msg.sender);
    } //
    event ManagerRemoved(address indexed removed, address indexed removedBy);

    // only by manager
    function setPriceForVerification(uint priceInWei) public {
        // see converter on https://etherconverter.online
        require(isManager[msg.sender]);
        uint oldPrice = priceForVerificationInWei;
        priceForVerificationInWei = priceInWei;
        PriceChanged(oldPrice, priceForVerificationInWei, msg.sender);
    } //
    event PriceChanged(uint from, uint to, address indexed changedBy);

    // !!! can be called by any user or contract
    // check for re-entrancy vulnerability http://solidity.readthedocs.io/en/develop/security-considerations.html#re-entrancy
    // >>> since we are making a withdrawal to our own contract only there is no possible attack using re-entrancy vulnerability,
    function withdrawAllToWithdrawalAddress() public returns (bool) {// (!) Gas requirement: infinite
        // http://solidity.readthedocs.io/en/develop/security-considerations.html#sending-and-receiving-ether
        // about <address>.send(uint256 amount) and <address>.transfer(uint256 amount)
        // see: http://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=transfer#address-related
        // https://ethereum.stackexchange.com/questions/19341/address-send-vs-address-transfer-best-practice-usage
        uint sum = this.balance;
        if (!withdrawalAddress.send(this.balance)) {// makes withdrawal and returns true or false
            Withdrawal(withdrawalAddress, sum, msg.sender, false);
            return false;
        }
        Withdrawal(withdrawalAddress, sum, msg.sender, true);
        return true;
    } //
    event Withdrawal(address indexed to, uint sumInWei, address indexed by, bool success);

    // only owner
    function setWithdrawalAddress(address _withdrawalAddress) public {
        require(msg.sender == owner);
        require(!withdrawalAddressFixed);
        WithdrawalAddressChanged(withdrawalAddress, _withdrawalAddress, msg.sender);
        withdrawalAddress = _withdrawalAddress;
    } //
    event WithdrawalAddressChanged(address indexed from, address indexed to, address indexed changedBy);

    // only owner
    function fixWithdrawalAddress(address _withdrawalAddress) public returns (bool) {
        require(msg.sender == owner);
        require(withdrawalAddress == _withdrawalAddress);

        // prevents event if already fixed
        require(!withdrawalAddressFixed);

        withdrawalAddressFixed = true;
        WithdrawalAddressFixed(withdrawalAddress, msg.sender);
        return true;
    } //
    // this event can be fired one time only
    event WithdrawalAddressFixed(address withdrawalAddressFixedAs, address fixedBy);

}