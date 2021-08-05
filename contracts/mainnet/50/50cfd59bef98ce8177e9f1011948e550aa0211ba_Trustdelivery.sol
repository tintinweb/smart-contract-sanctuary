pragma solidity >=0.4.0 <0.7.0;

import "./Identity.sol";

contract Trustdelivery {
    struct Member {
        string hash;
    }

    struct Certification {
        string member_hash;
        string data_hash_signed;
        string data_hash_type;
        string data_hash;
        string data_url;
    }


     // ************ Modifier *********** //
    modifier onlyManager() {
        require(msg.sender == owner, "Not allowed");
        _;
    }


    // ************* Events ********** //
    event MemberAdded(string, string);
    event MemberRemoved(string, string);
    event MemberUpdated(string, string);
    event certificationAdded(string, string, string, string);
    event IdentityContractSetted(string);


    address private owner;
    mapping (uint => Certification) private certifications;
    uint private counter;
    Identity private identityContract;



    constructor() public {
        counter = 0;
        owner = msg.sender;
    }

    function setIdentity(address _address_identity) external onlyManager {
        require(_address_identity != address(0), "Address is required");

        identityContract = Identity(_address_identity);
        emit IdentityContractSetted("The address of Identity contract was setted");

    }

    function setMember(string calldata hash, address _address) external onlyManager {
        require(bytes(hash).length > 0, "hash is required");
        require(_address != address(0), "address is required");

        identityContract.addMember(hash, _address);
        emit MemberAdded("New member was added with hash: ", hash);
    }

   function deleteMember(string calldata hash) external onlyManager {
       require(bytes(hash).length > 0, "hash is required");

       identityContract.removeMember(hash);
       emit MemberRemoved("Removed member with hash: ", hash);
   }

   function updateMember(string calldata hash, address _address) external onlyManager {
       require(bytes(hash).length > 0, "hash is required");
       require(_address != address(0), "address is required");

       identityContract.updateMember(hash, _address);
       emit MemberUpdated("Update member with hash: ", hash);

   }


   function setCertification(
    string calldata member_hash,
    string calldata data_hash_signed,
    string calldata data_hash,
    string calldata data_hash_type,
    string calldata data_url) external {
           require(bytes(member_hash).length > 0, "Member hash is required");
           require(bytes(data_hash_signed).length > 0, "Data hash signed is required");
           require(bytes(data_hash).length > 0, "Data hash is required");
           require(bytes(data_hash_type).length > 0, "Data hash type is required");
           require(bytes(data_url).length > 0, "Data url is required");

           if (identityContract.isTrusted(member_hash, msg.sender) == true) {
               Certification memory tmp_certification;
               tmp_certification.member_hash = member_hash;
               tmp_certification.data_hash_signed = data_hash_signed;
               tmp_certification.data_hash = data_hash;
               tmp_certification.data_hash_type = data_hash_type;
               tmp_certification.data_url = data_url;

               counter = counter + 1;
               certifications[counter] = tmp_certification;
               emit certificationAdded("New certification added. Member Hash: ", member_hash, " , Data Hash: ", data_hash);
           }

           else {
               revert("The member is not allowed to do this operation");
           }
       }


}