/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7; 
abstract contract NationManage{
    address private nation;

    constructor(){
        nation = msg.sender;
    }
    
    modifier onlyNation{
        require(nation == msg.sender);
        _;
    }
}

abstract contract IssuerManage is NationManage{ // onlyNation 사용을 위해 is 키워드 사용
    mapping(address => bool) public issuers;

    event AddIssuer(address _addr);
    event DelIssuer(address _addr);

    constructor(){
        issuers[msg.sender] = true;
    }

    modifier onlyIssuer{
        require(issuers[msg.sender]);
        _;
    }


    // onlyNation: 국가에서만 해당 함수 사용 가능
    // 새로운 제약회사에서 백신 개발 성공
    function addIssuer(address _addr) onlyNation public returns (bool){
        issuers[_addr] = true;
         require(issuers[_addr] == true); // 제대로 적용되었는지 확인
        emit AddIssuer(_addr);
        return true;
    }

    // 해당 제약회사의 백신 부작용이 밝혀짐에 따라 삭제 조치
    function delIssuer(address _addr) onlyNation public returns (bool){
        issuers[_addr] = false;
        require(issuers[_addr] == false); // 제대로 적용되었는지 확인
        emit DelIssuer(_addr);
        return true;
    }

    function isIssuer(address _addr) public view returns (bool){
        return issuers[_addr];
    }

}

contract VaccineCredential is IssuerManage{
    mapping(uint8 => string) private companyArr; // eg. 화이자, 모더나, AZ
    mapping(uint8 => string) private degreeArr;
    event SuccessCredential(string);
    event FaultCredential(string);

    // 접종자: 증명서 발급
    // 미접종자: 증명서 발급 불가
    struct Credential{
        uint id;
        string company; // 백신 제조사: 화이자, 모더나, AZ
        string degree; // 접종 차수: 1차, 2차, 3차
        uint createdDate; // 접종 일자
        string value; // credentail에 포함되어야하는 암호화된 정보
    }
    mapping(address => Credential) private credentials;

    constructor(){
        companyArr[0] = unicode"🧪화이자";
        companyArr[1] = unicode"🧪모더나";
        companyArr[2] = unicode"🧪AZ";

        degreeArr[1] = unicode"1️⃣차 접종 완료";
        degreeArr[2] = unicode"2️⃣차 접종 완료";
        degreeArr[3] = unicode"3️⃣차 접종 완료";
    }

    // onlyIssuer: 허가받은 제약회사에서만 claim 발행 가능
    function claimCredential(address _requester, uint8 _companyEnum, uint8 _degreeEnum, string calldata _value) onlyIssuer public returns (bool){
        if(_degreeEnum <= 0){
            emit FaultCredential(unicode"❌발급 가능한 증명서가 없습니다❌");
            return false;
        }
        emit SuccessCredential(unicode"✅증명서가 발급되었습니다✅");
        Credential storage credential = credentials[_requester]; // 발급한 credential은 storage에 저장하여 블록체인에 영구적으로 기록
        credential.id = 1;
        credential.company = companyArr[_companyEnum];
        credential.degree = degreeArr[_degreeEnum];
        credential.createdDate = block.timestamp;
        credential.value = _value;
        return true;
    }
    function getCredential(address _requester) public view returns (Credential memory credential){
        require(credentials[_requester].id != 0, unicode"❌발급 가능한 증명서가 없습니다❌");
        return credentials[_requester];
    }
}