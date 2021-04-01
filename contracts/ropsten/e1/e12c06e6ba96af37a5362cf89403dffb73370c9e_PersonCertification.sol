/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.4.11;

// 본인 확인 계약
contract PersonCertification {
 
    // 계약 관리자 주소
    address admin;
 
    // (1) 열람 허가 정보
    struct AppDetail {
        bool allowReference;
        uint256 approveBlockNo;
        uint256 refLimitBlockNo;
        address applicant;
    }
 
    // (2) 본인 확인 정보(홍길동)
    struct PersonDetail {
        string name;
        string birth;
        address[] orglist;
    }
 
    // (3) 인증 기관 정보(학교, 회사 등)
    struct OrganizationDetail {
        string name;
    }
 
    // (4) 해당 키의 열람 허가 정보
    mapping(address => AppDetail) appDetail;
 
    // (5) 해당 키의 본인 확인 정보
    mapping(address => PersonDetail) personDetail;
 
    // (6) 해당 키의 조직 정보
    mapping(address => OrganizationDetail) public orgDetail;
 
    // (7) 생성자
    function PersonCertification() {
        admin = msg.sender;
    }
 
    // ---------------------------------------------------------------------
    // 데이터 등록 기관(set)
    // ---------------------------------------------------------------------
    // (8) 본인 정보를 등록
    function setPerson(string _name, string _birth) {
        personDetail[msg.sender].name = _name;
        personDetail[msg.sender].birth = _birth;
    }
 
    // (9) 조직 정보를 등록
    function setOrganization(string _name) {
         orgDetail[msg.sender].name = _name;
    }
 
    // (10) 조직이 개인의 소속을 증명
    function setBelong(address _person) {
        personDetail[_person].orglist.push(msg.sender);
    }
 
    // (11) 본인 확인 정보 참조를 허가
    function setApprove(address _applicant, uint256 _span) {
        appDetail[msg.sender].allowReference = true;
        appDetail[msg.sender].approveBlockNo = block.number;
        appDetail[msg.sender].refLimitBlockNo = block.number + _span;
        appDetail[msg.sender].applicant = _applicant;
    }
 
    // ---------------------------------------------------------------------
    // 데이터 취득 함수(get)
    // ---------------------------------------------------------------------
    // (12) 본인 확인 정보를 참조
    function getPerson(address _person) public constant returns(
                                        bool _allowReference,
                                        uint256 _approveBlockNo,
                                        uint256 _refLimitBlockNo,
                                        address _applicant,
                                        string _name,
                                        string _birth,
                                        address[] _orglist) {
        // (12-1) 열람을 허가할 정보
        _allowReference  = appDetail[_person].allowReference;
        _approveBlockNo  = appDetail[_person].approveBlockNo;
        _refLimitBlockNo = appDetail[_person].refLimitBlockNo;
        _applicant       = appDetail[_person].applicant;
        // (12-2) 열람을 제한할 정보
        if (((msg.sender == _applicant) 
          && (_allowReference == true) 
          && (block.number < _refLimitBlockNo)) 
         || (msg.sender == admin) 
         || (msg.sender == _person)) {
            _name    = personDetail[_person].name;
            _birth   = personDetail[_person].birth;
            _orglist = personDetail[_person].orglist;
        }
    }
}