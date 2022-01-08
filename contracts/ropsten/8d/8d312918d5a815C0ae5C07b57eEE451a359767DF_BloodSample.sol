/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

contract Agreement{
    string hospital_id;
    string bloodBank_id;
    string bloodSample_id;
    string agreement_id;
    constructor(string memory h, string memory bb, string memory b, string memory a)  {
        hospital_id = h;
        bloodBank_id = bb;
        bloodSample_id = b;
        agreement_id = a;
    }
    function check_Hospital_query(string memory h_id) public view returns(bool){
        if (keccak256(abi.encodePacked(hospital_id)) == keccak256(abi.encodePacked(h_id))){
            return true;
        }
        return false;
    }
    function check_bloodBank_query(string memory bb_id) public view returns(bool){
        if (keccak256(abi.encodePacked(bb_id)) == keccak256(abi.encodePacked(bloodBank_id))){
            return true;
        }
        return false;
    }
    function check_bloodSample_query(string memory blood_id) public view returns(bool){
        if (keccak256(abi.encodePacked(blood_id)) == keccak256(abi.encodePacked(bloodSample_id))){
            return true;
        }
        return false;
    }
    function view_result() public view returns(string memory,string memory,string memory,string memory){
        return (hospital_id, bloodBank_id, bloodSample_id, agreement_id);
    }
}
contract BloodSample {
    enum BLOOD_STATUS{
            COLLECTED,
            TESTED_OK,
            TESTED_NOT_OK,
            EXPIRED,
            REQUESTED,
            SENT_TO_HOSPITAL
    }
    struct blood{
        string d_id ;
        string bb_id ;
        string blood_id;
        string blood_type;
        BLOOD_STATUS state;
    }
    blood[] public bloodBags;
    mapping(string=>uint256) public index_to_blood_bag;
    Agreement[] public agreements;
    mapping(string=>uint256[]) public bb_id_to_blood_bags_index;
    mapping(string=>uint256[]) public d_id_to_blood_bags_index;
    function collected(string memory d_id,string memory bb_id,string memory blood_id, string memory blood_type) public{
        bloodBags.push(blood({d_id: d_id, bb_id: bb_id, blood_id: blood_id, blood_type: blood_type, state: BLOOD_STATUS.COLLECTED}));
        uint256 l = bloodBags.length-1;
        bb_id_to_blood_bags_index[bb_id].push(l);
        d_id_to_blood_bags_index[d_id].push(l);
        index_to_blood_bag[blood_id] = l;
    }
    function tested(string memory blood_id, string memory test) public  {
        blood storage b = bloodBags[index_to_blood_bag[blood_id]];
        string memory a = "OK";
        if (keccak256(abi.encodePacked(test)) == keccak256(abi.encodePacked(a))){
            b.state = BLOOD_STATUS.TESTED_OK;
        }else{
            b.state = BLOOD_STATUS.TESTED_NOT_OK;
        }
    }
    function expired(string memory blood_id) public {
        blood storage b = bloodBags[index_to_blood_bag[blood_id]];
        b.state = BLOOD_STATUS.EXPIRED;
    }
    function expiry_check(string memory blood_id) public view returns(bool){
        blood memory b = bloodBags[index_to_blood_bag[blood_id]];
        if (b.state == BLOOD_STATUS.EXPIRED){
            return true;
        }
        return false;
    }
    function request_check(string memory blood_id) public view returns(bool){
        blood memory b = bloodBags[index_to_blood_bag[blood_id]];
        if (b.state == BLOOD_STATUS.REQUESTED){
            return true;
        }
        return false;
    }
    function requested(string memory blood_id, string memory h_id, string memory a_id) public {
        blood storage b = bloodBags[index_to_blood_bag[blood_id]];
        require(!expiry_check(blood_id));
        b.state = BLOOD_STATUS.REQUESTED;
        Agreement a = new Agreement(h_id,b.bb_id,blood_id,a_id);
        agreements.push(a);
    }
    function query_agreement_for_hospital(string memory h_id) public view returns (Agreement[] memory){
        Agreement[] memory result = new Agreement[](agreements.length);
        uint k=0;
        for(uint256 i=0;i<agreements.length;i++){
            Agreement a = agreements[i];
            if (a.check_Hospital_query(h_id)){
                result[k] = a;
                k++;
            }
        }
        return result;
    }
    function query_agreement_for_bloodbank(string memory bb_id) public view returns (Agreement[] memory){
        Agreement[] memory result = new Agreement[](agreements.length);
        uint k=0;
        for(uint256 i=0;i<agreements.length;i++){
            Agreement a = agreements[i];
            if (a.check_bloodBank_query(bb_id)){
                result[k] = a;
                k++;
            }
        }
        return result;
    }
    function get_agreement_details(address add) public view returns (string memory,string memory,string memory,string memory){
        Agreement a = Agreement(add);
        return a.view_result();
    }
    function sent(string memory blood_id)public {
        blood storage b = bloodBags[index_to_blood_bag[blood_id]];
        require(request_check(blood_id));
        b.state = BLOOD_STATUS.SENT_TO_HOSPITAL;
    }
    function eligible_blood_bags(string memory blood_type) public view returns(blood[] memory){
        blood[] memory result = new blood[](bloodBags.length);
        uint k = 0;
        for (uint256 i=0; i<bloodBags.length ; i++){
            blood memory b = bloodBags[i];
            if (b.state == BLOOD_STATUS.TESTED_OK && keccak256(abi.encodePacked(blood_type)) == keccak256(abi.encodePacked(b.blood_type))){
                result[k] = b;
                k++;
            }
        }
        return result;
    }
    function bbank_no_samples_collected(string memory bb_id) public view returns(blood[] memory){
        uint256[] memory index = bb_id_to_blood_bags_index[bb_id];
        blood[] memory result = new blood[](index.length);
        uint k = 0;
        for (uint256 i=0;i<index.length;i++){
            uint256 ind = index[i];
            blood memory b = bloodBags[ind];
            result[k] = b;
            k++;
        }
        return result;
    }
    function sent_blood_samples(string memory bb_id) public view returns(blood[] memory){
        uint256[] memory index = bb_id_to_blood_bags_index[bb_id];
        blood[] memory result = new blood[](bloodBags.length);
        uint k = 0;
        for (uint256 i=0; i<index.length ; i++){
            uint256 ind = index[i];
            blood memory b = bloodBags[ind];
            if (b.state == BLOOD_STATUS.SENT_TO_HOSPITAL ){
                result[k] = b;
                k++;
            }
        }
        return result;
    }
    function expired_blood_samples(string memory bb_id) public view returns(blood[] memory){
        uint256[] memory index = bb_id_to_blood_bags_index[bb_id];
        blood[] memory result = new blood[](bloodBags.length);
        uint k = 0;
        for (uint256 i=0; i<index.length ; i++){
            uint256 ind = index[i];
            blood memory b = bloodBags[ind];
            if (b.state == BLOOD_STATUS.EXPIRED ){
                result[k] = b;
                k++;
            }
        }
        return result;
    }
}